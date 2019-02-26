//
//  UDPObject.m
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import "UDPObject.h"

@interface UDPObject()

@property (nonatomic, strong) GCDAsyncUdpSocket * socket;
@property (nonatomic, strong) NSString * host;



//client
@property (nonatomic, assign) DataType  sendType;
@property (nonatomic, assign) NSInteger  total_pack;
@property (nonatomic, strong) NSMutableDictionary * sendDic;     //发送信息

//server
@property (nonatomic, strong) NSMutableDictionary * imgDic;
@property (nonatomic, strong) NSMutableDictionary * notReciveDic;

@end



@implementation UDPObject


- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_queue_create("udp.info.proccess.queue", 0);
        self.socket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:queue];
    }
    return self;
}


- (BOOL)run {
    NSError * error;
    
    [self.socket setIPv6Enabled:NO];
    
    [self.socket bindToPort:self.port error:&error];
    
    
    if ([self checkSocketError:error]) { return NO; }
    
    //监听成功则开始接收信息
    [self.socket enableBroadcast:YES error:&error];
    
    if ([self checkSocketError:error]) { return NO; }
    
    [self.socket beginReceiving:&error];
    
    
    return  YES;
}

- (void)close {
    [self.socket close];
}


- (void)sendData:(NSData *)data dataType:(DataType)type {
    
    
    
    if (data.length > PACK_SIZE) {

        NSInteger total_pack = (data.length - 1) / PACK_SIZE + 1;
        NSInteger len = PACK_SIZE;
        NSLog(@"总包数:%ld,长度:%ld",total_pack,data.length);
        self.sendDic = [NSMutableDictionary dictionaryWithCapacity:total_pack];
        for (int i = 0; i < total_pack; i++) {
            if ((len + i * PACK_SIZE) > data.length) {
                len = data.length - i * PACK_SIZE;
            }
            NSString * key = [NSString stringWithFormat:@"%d",i];
            self.sendDic[key] = [data subdataWithRange:NSMakeRange(i * PACK_SIZE, len)];
        }
        self.sendType = type;
        self.total_pack = total_pack;
        NSLog(@"%@",self.sendDic.allKeys);
        // 发送给消息让客户端准备好接收
        NSMutableData * sendData = [NSMutableData dataWithData:[self proccessHeaderDataType:type transType:TransTypePrepare packNum:0 totalPack:(int)total_pack]];
        [self.socket sendData:sendData toHost:self.ip port:self.port withTimeout:-1 tag:1050];
        
    } else {
        //信息发送
        NSMutableData * sendData = [NSMutableData dataWithData:[self proccessHeaderDataType:type transType:TransTypeIgnore]];
        [sendData appendData:data];
        [self sendData:sendData host:self.ip port:self.port];
    }
}


- (void)sendPack:(NSDictionary *)packDic host:(NSString *)host port:(NSInteger)port {
    
    for (NSString * key in packDic.allKeys) { //发送文件分割包
        NSMutableData * sendData = [NSMutableData dataWithData:[self proccessHeaderDataType:self.sendType transType:TransTypeDoing packNum:(int)[key integerValue] totalPack:(int)self.total_pack]];
        [sendData appendData:packDic[key]];
        [self sendData:sendData host:self.ip port:self.port];
    }
    
    [NSThread sleepForTimeInterval:0.01];
    // 发送完成
    NSMutableData * sendData = [NSMutableData dataWithData:[self proccessHeaderDataType:self.sendType transType:TransTypeSendEnd]];
    [self sendData:sendData host:self.ip port:self.port];
}

// 发送包
- (void)sendData:(NSData *)data host:(NSString *)host port:(NSInteger)port {
    [self.socket sendData:data toHost:host port:port withTimeout:-1 tag:1050];
}


- (BOOL)checkSocketError:(NSError *)error {
    if (error && [self.delegate respondsToSelector:@selector(udpRunError:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate udpRunError:self error:error];
        });
        return YES;
    }
    return NO;
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"%@ udp链接成功!",sock);
    if ([self.delegate respondsToSelector:@selector(udpConnectSuccess:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate udpConnectSuccess:self];
        });
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    NSLog(@"udp无法链接: %@!",error.localizedDescription);
    [self checkSocketError:error];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"%@ 消息发送成功!",sock);
    if ([self.delegate respondsToSelector:@selector(udpSendDataSuccess:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate udpSendDataSuccess:self];
        });
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    NSLog(@"消息发送失败: %@",error.localizedDescription);
    [self checkSocketError:error];
}

// 接收到消息后处理
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(nullable id)filterContext {
    
    if ([self verifyData:data]) {
        
        DataType dataType = [self getDataType:data];
        TransType transType = [self getTransType:data];
        NSInteger total_pack = [self getTotalPack:data];
        
        if (transType == TransTypeIgnore) { //直接回调展示数据
            NSLog(@"收到新消息!");
            [self callDelegateReciveData:[self getBodydata:data] dataType:dataType];
        } else if  (transType == TransTypeDoing) { //开始传输
            int packNum = [self getPackNum:data];
            if (packNum >= 0 && packNum < total_pack && [self getBodydata:data]) {
                NSString * key = [NSString stringWithFormat:@"%d",packNum];
                self.imgDic[key] = [self getBodydata:data];
                self.notReciveDic[key] = nil;
            }
        } else if (transType == TransTypePrepare) { //服务端开始准备
            self.notReciveDic = [NSMutableDictionary dictionaryWithCapacity:total_pack];
            self.imgDic = [NSMutableDictionary dictionaryWithCapacity:total_pack];
            for (int i = 0; i < total_pack; i++) {
                self.notReciveDic[[NSString stringWithFormat:@"%d",i]] = @"";
            }
            NSLog(@"总包数:%ld 接收包数:%@", total_pack ,self.notReciveDic);
            //回复客户端准备完成
            NSString * ip = [GCDAsyncUdpSocket hostFromAddress:address];
            NSData * sendData = [self proccessHeaderDataType:dataType transType:TransTypeReday];
            [self sendData:sendData host:ip port:self.port];
            
        } else if (transType == TransTypeReday) { //服务端准备完成
            [self sendPack:self.sendDic host:self.ip port:self.port]; //开始发送数据
        } else if (transType == TransTypeSendEnd) {
            
            if (self.notReciveDic.allKeys.count == 0) { //包全部接收
                // 字典key值排序
                NSArray * keyArr = [self.imgDic.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
                    return [obj2 integerValue] < [obj1 integerValue];
                }];

                NSMutableData * muData = [NSMutableData data];
                for (NSString * key in keyArr) {
                    [muData appendData:self.imgDic[key]];
                }
                 NSLog(@"总包数:%ld,长度:%ld",keyArr.count, muData.length);
                [self callDelegateReciveData:muData dataType:dataType];
            } else { //包接收丢失，要求客户端重发丢失部分
                NSLog(@"要求重发包:%@",self.notReciveDic.allKeys);
                NSMutableData * sendData = [NSMutableData dataWithData:[self proccessHeaderDataType:dataType transType:TransTypeRetry]];
                [sendData appendData:[[self.notReciveDic.allKeys jsonString] dataUsingEncoding:NSUTF8StringEncoding]];
                NSString * ip = [GCDAsyncUdpSocket hostFromAddress:address];
                [self sendData:sendData host:ip port:self.port];
            }
        } else if (transType == TransTypeRetry) { //重发部为数组，值为包的序列号
            NSLog(@"重发丢失的包");
            NSData * body = [self getBodydata:data];
            NSArray * array = [NSJSONSerialization JSONObjectWithData:body options:NSJSONReadingAllowFragments error:nil];
            NSMutableDictionary * reSendDic = [NSMutableDictionary dictionaryWithCapacity:array.count];
            for (NSString * key in array) {
                reSendDic[key] = self.sendDic[key];
            }
            [self sendPack:reSendDic host:self.ip port:self.port];
        }
        
    }
}

- (void)callDelegateReciveData:(NSData *)data dataType:(DataType)type {
    if ([self.delegate respondsToSelector:@selector(udp:reciveData:dataType:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate udp:self reciveData:data dataType:type];
        });
    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    [self checkSocketError:error];
}


#pragma mark - 报头校验相关

/*
 报头分4部分共6字节
 1字节 : 类型
 2字节 : 传输类型
 3-4字节 : 当前包序列号
 5-6字节 : 总包数
 */

- (NSData *)proccessHeaderDataType:(DataType)dataType transType:(TransType)transType packNum:(int)packNum totalPack:(int)totalPack {
    NSMutableData * output = [NSMutableData data];
    int len = sizeof(int);
    [output appendData:[[NSData dataWithInt:dataType] subdataWithRange:NSMakeRange(len - 1, 1)]];
    [output appendData:[[NSData dataWithInt:transType] subdataWithRange:NSMakeRange(len - 1, 1)]];
    [output appendData:[[NSData dataWithInt:packNum] subdataWithRange:NSMakeRange(len - 2, 2)]];
    [output appendData:[[NSData dataWithInt:totalPack] subdataWithRange:NSMakeRange(len - 2, 2)]];
    return output;
}

- (NSData *)proccessHeaderDataType:(DataType)dataType
                         transType:(TransType)transType {
    return [self proccessHeaderDataType:dataType transType:transType packNum:0 totalPack:1];
}

- (BOOL)verifyData:(NSData *)data {
    if (data.length < 6) { return NO; }
    NSInteger type = [self getDataType:data];
    return type == DataTypeStr || type == DataTypeImg || type == DataTypeFile;
}

- (NSData *)getBodydata:(NSData *)data {
    if (data.length > 6) {
        return [data subdataWithRange:NSMakeRange(6, data.length - 6)];
    }
    return nil;
}

- (DataType)getDataType:(NSData *)data {
    return [[data subdataWithRange:NSMakeRange(0, 1)] kkl_intValue];
}
- (TransType)getTransType:(NSData *)data {
    return [[data subdataWithRange:NSMakeRange(1, 1)] kkl_intValue];
}
- (int)getPackNum:(NSData *)data {
    return [[data subdataWithRange:NSMakeRange(2, 2)] kkl_intValue];
}
- (int)getTotalPack:(NSData *)data {
    return [[data subdataWithRange:NSMakeRange(4, 2)] kkl_intValue];
}

@end
