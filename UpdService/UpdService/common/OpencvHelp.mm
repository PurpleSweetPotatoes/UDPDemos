//
//  OpencvHelp.m
//  UpdService
//
//  Created by baiqiang on 2019/2/20.
//  Copyright © 2019年 baiqiang. All rights reserved.
//

#import "OpencvHelp.h"

@implementation OpencvHelp

using namespace cv;


+ (UIImage *)toGray:(UIImage *)source {
    Mat mat;
    UIImageToMat(source,mat);
    
    return MatToUIImage([self grayFrom:mat]);
}

+ (Mat)grayFrom:(Mat)source {
    Mat result;
    cvtColor(source, result, CV_BGR2GRAY);
    return result;
}


+ (UIImage *)getBinaryImage:(UIImage *)source {
    Mat mat;
    UIImageToMat(source,mat);
    
    Mat gray;
    cvtColor(mat, gray, CV_RGB2GRAY);
    
    Mat bin;
    threshold(gray, bin, 0, 255, THRESH_BINARY | THRESH_OTSU);
    
    return MatToUIImage([self grayFrom:mat]);
}

+ (UIImage *)imageMatfromData:(NSData *)data {
    Mat mat = Mat(1,(int)[data length],CV_8UC1,(void*)data.bytes);
    Mat cv_src = imdecode(mat,CV_LOAD_IMAGE_COLOR);
    //Mat存取图片的矩阵是按照BGR,将BGR转为RGB
    cvtColor(cv_src, cv_src, CV_BGR2RGB);
    
    return MatToUIImage(cv_src);
}

@end
