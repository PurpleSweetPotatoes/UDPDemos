//
//  OpencvHelp.h
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 when change type in cv::Mat and UIImage, use the two methods
 
 UIImage* MatToUIImage(const cv::Mat& image);
 
 void UIImageToMat(const UIImage* image,cv::Mat& m, bool alphaExist = false);
 */

NS_ASSUME_NONNULL_BEGIN

@interface OpencvHelp : NSObject

+ (UIImage *)toGray:(UIImage *)source;
+ (UIImage *)getBinaryImage:(UIImage *)source;
+ (UIImage *)imageMatfromData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
