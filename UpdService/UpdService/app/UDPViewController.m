//
//  UDPViewController.m
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import "UDPViewController.h"
#import "UDPObject.h"

#import "UDPMsgCell.h"

@interface UDPViewController ()
<
UITableViewDataSource,
UITableViewDelegate,
UDPObjectDelegate
>

@property (nonatomic, strong) UIImageView * imageView;
//server
@property (nonatomic, strong) BQTextView * textView;
//client
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray<NSString *> * msgArr;
@end

@implementation UDPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorFromHexString:@"ebebeb"];
    
    self.title = [NSString stringWithFormat:@"%@%@",self.udpService.isSend ? @"发送至: ":@"本机ip: ", self.udpService.ip];
    
    self.msgArr = [NSMutableArray array];
    
    
    [self.msgArr addObject:@"监听端口信息"];
    
    self.udpService.delegate = self;
    
    [self setUpUI];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar lt_reset];
    [self.udpService run];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.udpService close];
}



- (void)setUpUI {
    
    CGFloat imgWidth = 240;
    
    UIImageView * imgView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.sizeW - imgWidth) * 0.5, KNavBottom + 20, imgWidth,  imgWidth * 9 / 16)];
    imgView.backgroundColor = [UIColor whiteColor];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imgView];
    self.imageView = imgView;
    
    if (self.udpService.isSend) {
        
        imgView.left -= 50;
        
        UIButton * selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        selectBtn.frame = CGRectMake(imgView.right + 10, imgView.top + imgView.sizeH * 0.25 - 15, imgWidth * 0.5 - 20, 30);
        [selectBtn addTarget:self action:@selector(selectBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        selectBtn.backgroundColor = [UIColor whiteColor];
        selectBtn.layer.cornerRadius = 10;
        selectBtn.clipsToBounds = YES;
        selectBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [selectBtn setTitle:@"select img" forState:UIControlStateNormal];
        [selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:selectBtn];
        
        UIButton * sendImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        sendImgBtn.frame = selectBtn.frame;
        sendImgBtn.top = imgView.top + imgView.sizeH * 0.75 - 15;
        sendImgBtn.layer.cornerRadius = 10;
        sendImgBtn.clipsToBounds = YES;
        [sendImgBtn addTarget:self action:@selector(sendImgBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        sendImgBtn.backgroundColor = [UIColor whiteColor];
        sendImgBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [sendImgBtn setTitle:@"send img" forState:UIControlStateNormal];
        [sendImgBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:sendImgBtn];
        
    
        BQTextView * textView = [[BQTextView alloc] initWithFrame:CGRectMake(imgView.left, imgView.bottom + 20, imgView.sizeW,  40)];
        textView.autoAdjustHeight = YES;
        textView.placeholder = @"请输入要发送的消息";
        [self.view addSubview:textView];
        self.textView = textView;
        
        UIButton * sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        sendBtn.frame = selectBtn.frame;
        sendBtn.top = textView.top + 2;
        sendBtn.layer.cornerRadius = 10;
        sendBtn.clipsToBounds = YES;
        [sendBtn addTarget:self action:@selector(sendBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        sendBtn.backgroundColor = [UIColor whiteColor];
        sendBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [sendBtn setTitle:@"send msg" forState:UIControlStateNormal];
        [sendBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:sendBtn];
        
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewEndEdit:)];
        [self.view addGestureRecognizer:tap];
        
    } else {
        
        UILabel * imgLab = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.bottom + 5, self.view.sizeW, 20)];
        imgLab.font = [UIFont systemFontOfSize:14];
        imgLab.textAlignment = NSTextAlignmentCenter;
        imgLab.text = @"recive image show";
        [self.view addSubview:imgLab];
        
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, imgLab.bottom + 10, 200, 20)];
        label.font = [UIFont systemFontOfSize:15];
        label.text = @"recive message log";
        [self.view addSubview:label];
        
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(20, label.bottom + 10, self.view.sizeW - 40, self.view.sizeH - (label.bottom + 10) - 20 ) style:UITableViewStylePlain];
        [tableView registerCell:[UDPMsgCell class] isNib:YES];
        tableView.tableFooterView = [[UIView alloc] init];
        tableView.delegate = self;
        tableView.dataSource = self;
        [self.view addSubview:tableView];
        self.tableView = tableView;
        
    }
   
}

#pragma mark - UDPObjectDelegate

- (void)udpConnectSuccess:(UDPObject *)udpService {
    [self reciveNewMsg:@"链接服务器成功"];
}

- (void)udpSendDataSuccess:(UDPObject *)udpService {
    self.textView.text = @"";
}

- (void)udp:(UDPObject *)udpService reciveData:(NSData *)data dataType:(DataType)type {
    
    if (type == DataTypeStr) {
        [self reciveNewMsg:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    } else if (type == DataTypeImg) {
        self.imageView.image = [UIImage imageWithData:data];
    } else if (type == DataTypeFile) {
        
    }
}

- (void)udpRunError:(UDPObject *)udpService error:(NSError *)error {
    NSLog(@"upd出错:%@",error.localizedDescription);
    [self reciveNewMsg:error.localizedDescription];
}


- (void)reciveNewMsg:(NSString *)msg {
    NSLog(@"接收到消息: %@",msg);
    [self.msgArr insertObject:msg atIndex:0];
    [self.tableView reloadData];
    
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.msgArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView fetchCellHeight:[UDPMsgCell class] configBlock:^(UDPMsgCell * cell) {
        [cell configInfo:self.msgArr[indexPath.row]];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UDPMsgCell * cell = (UDPMsgCell *)[tableView loadCell:[UDPMsgCell class] indexPath:indexPath];
    [cell configInfo:self.msgArr[indexPath.row]];
    return cell;
}

#pragma mark - Btn Action
- (void)selectBtnAction:(UIButton *)sender {
    NSLog(@"选择相片");
    WeakSelf;
    [BQImagePicker showPickerImageWithHandleImage:^(UIImage *image) {
        StrongSelf;
        strongSelf.imageView.image = image;
    }];
}

- (void)sendImgBtnAction:(UIButton *)sender {
    NSLog(@"发送图片");
    
    UIImage * image = [OpencvHelp toGray:self.imageView.image];
//    NSData * data = [UIImage compressImageWithImage:image aimLength:1024 * 100 accurancyOfLength:10 maxCircleNum:8];
    NSData * data = UIImageJPEGRepresentation(image, 1);
    self.imageView.image = nil;
    [self.udpService sendData:data dataType:DataTypeImg];

}

- (void)sendBtnAction:(UIButton *)sender {
    NSLog(@"发送消息");
    if (self.textView.text.length > 0) {
        [self.udpService sendData:[self.textView.text dataUsingEncoding:NSUTF8StringEncoding] dataType:DataTypeStr];
    }
    
}


- (void)viewEndEdit:(UITapGestureRecognizer *)sender {
    NSLog(@"关闭键盘");
    [self.view endEditing:YES];
}
@end
