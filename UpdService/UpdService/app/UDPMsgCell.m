//
//  UDPMsgCell.m
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import "UDPMsgCell.h"

@interface UDPMsgCell()
@property (weak, nonatomic) IBOutlet UILabel *msgLabel;


@end

@implementation UDPMsgCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.msgLabel.frame = CGRectMake(8, 8, KScreenWidth - 56, 0);
}

- (void)configInfo:(NSString *)info {
    self.msgLabel.text = info;
    [self.msgLabel heightToFit];
    self.sizeH = self.msgLabel.bottom + 8;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
