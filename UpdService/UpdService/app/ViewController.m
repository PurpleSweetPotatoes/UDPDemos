//
//  ViewController.m
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import "ViewController.h"
#import "UDPViewController.h"

#import "UDPObject.h"

@interface ViewController ()

@property (nonatomic, strong) UILabel * ipAddressLabel;
@property (nonatomic, copy) NSString * ip;

@property (nonatomic, strong) UITextField * ipTF;
@property (nonatomic, strong) UITextField * portTF;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor colorFromHexString:@"0071BD"];
    
    [self setUpUI];
    
    self.portTF.text = [NSString stringWithFormat:@"%d",SRV_PORT];
    self.ipTF.text = @"192.168.";
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewEndEdit:)];
    [self.view addGestureRecognizer:tap];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];
    self.ip = [UIDevice ip4Address];
    self.ipAddressLabel.text = [NSString stringWithFormat:@"当前ip: %@",self.ip];
}


- (void)setUpUI {
    UIImageView * imgView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.sizeW - 60) * 0.5, 100, 60, 60)];
    UIImage * img = [UIImage imageNamed:@"icon"];
    
    NSData * data = UIImageJPEGRepresentation(img, 1);
    //用于检测opencv是否可
    //img = [OpencvHelp toGray:img];
    
    imgView.image = [OpencvHelp imageMatfromData:data];
    
    [self.view addSubview:imgView];
    
    
    UILabel * ipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, imgView.bottom + 20, self.view.sizeW, 20)];
    ipLabel.textAlignment = NSTextAlignmentCenter;
    ipLabel.textColor = [UIColor whiteColor];
    ipLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:ipLabel];
    self.ipAddressLabel = ipLabel;
    
    CGFloat viewWidth = 250;
    
    self.ipTF = [self configTextFeildWithFrame:CGRectMake((self.view.sizeW - viewWidth) * 0.5, ipLabel.bottom + 50, viewWidth, 40) placeHolder:@"请输入服务器ip地址"];
    self.portTF = [self configTextFeildWithFrame:CGRectMake((self.view.sizeW - viewWidth) * 0.5, self.ipTF.bottom + 10, viewWidth, 40) placeHolder:@"请输入端口号"];
    
    
    viewWidth = 120;
    UIButton * sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendBtn.frame = CGRectMake((self.view.sizeW - viewWidth ) * 0.5, self.portTF.bottom + 20, viewWidth, 30);
    sendBtn.layer.cornerRadius = 4;
    sendBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    sendBtn.layer.borderWidth = 1;
    [sendBtn addTarget:self action:@selector(sendBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    sendBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [sendBtn setTitle:@"send to server" forState:UIControlStateNormal];
    [sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:sendBtn];
    
    UIButton * serverBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    serverBtn.layer.cornerRadius = 4;
    serverBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    serverBtn.layer.borderWidth = 1;
    serverBtn.frame = sendBtn.frame;
    serverBtn.top = sendBtn.bottom + 10;
    [serverBtn addTarget:self action:@selector(startServerBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    serverBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [serverBtn setTitle:@"start upd listen" forState:UIControlStateNormal];
    [serverBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:serverBtn];
}

- (UITextField *)configTextFeildWithFrame:(CGRect)frame placeHolder:(NSString *)placeHolder {
    UITextField * tf = [[UITextField alloc] initWithFrame:frame];
    tf.backgroundColor = [UIColor whiteColor];
    tf.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.layer.cornerRadius = 10;
    tf.clipsToBounds = YES;
    tf.font = [UIFont systemFontOfSize:14];
    tf.placeholder = placeHolder;
    [self.view addSubview:tf];
    return  tf;
}


#pragma mark - Btn Action

- (void)startServerBtnAction:(UIButton *)sender {
    NSLog(@"开启UDP服务器:");
    
    UDPObject * service = [[UDPObject alloc] init];
    service.ip = self.ip;
    service.port = [self.portTF.text integerValue];
    [self pushToUdpVc:service];
}

- (void)sendBtnAction:(UIButton *)sender {
    NSLog(@"发送信息至UDP服务器:");
    UDPObject * service = [[UDPObject alloc] init];
    service.ip = self.ipTF.text;
    service.port = [self.portTF.text integerValue];
    service.isSend = YES;
    [self pushToUdpVc:service];
}

- (void)pushToUdpVc:(UDPObject *)udpService {
    UDPViewController * udpVc = [[UDPViewController alloc] init];
    udpVc.udpService = udpService;
    [self.navigationController pushViewController:udpVc animated:YES];
}

- (void)viewEndEdit:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
}


@end

