//
//  UDPObject.h
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "updSocketConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DataType) {
    DataTypeStr,                // 文字
    DataTypeImg,                // 图片
    DataTypeFile                // 文件
};

typedef NS_ENUM(NSUInteger, TransType) {
    TransTypePrepare,               // 客户端发送给服务器提示要传大文件
    TransTypeReday,                 // 服务器发送给客户端已准备好接受
    TransTypeDoing,                 // 客户端发送文件中
    TransTypeSendEnd,               // 客户端发送完成，询问服务端接收情况
    TransTypeReciveEnd,             // 服务端发送客户端接收完成
    TransTypeRetry,                 // 要求客户端重发丢包数据
    TransTypeIgnore                 // 用于单个包发送
};

@class UDPObject;

@protocol UDPObjectDelegate <NSObject>

@optional

- (void)udpConnectSuccess:(UDPObject *)udpService;

- (void)udpRunError:(UDPObject *)udpService error:(NSError *)error;

- (void)udpSendDataSuccess:(UDPObject *)udpService;

@required
- (void)udp:(UDPObject *)udpService reciveData:(NSData *)data dataType:(DataType)type;

@end



@interface UDPObject : NSObject <GCDAsyncUdpSocketDelegate>
@property (nonatomic, weak) id<UDPObjectDelegate>  delegate;
@property (nonatomic, copy) NSString * ip;
@property (nonatomic, assign) NSInteger  port;
@property (nonatomic, assign) BOOL  isSend;
@property (nonatomic, strong) NSString * reciveAddress;         ///< 消息来源ip地址


- (NSData *)proccessHeaderDataType:(DataType)dataType
                         transType:(TransType)transType;

- (NSData *)proccessHeaderDataType:(DataType)dataType
                         transType:(TransType)transType
                           packNum:(int)packNum
                         totalPack:(int)totalPack;

- (BOOL)verifyData:(NSData *)data;
- (DataType)getDataType:(NSData *)data;
- (TransType)getTransType:(NSData *)data;
- (int)getPackNum:(NSData *)data;
- (int)getTotalPack:(NSData *)data;
- (NSData *)getBodydata:(NSData *)data;


- (void)sendData:(NSData *)data dataType:(DataType)type;

- (BOOL)run;
- (void)close;

@end

NS_ASSUME_NONNULL_END
