//
//  SecondViewController.m
//  CameraCaptureTest
//
//  Created by tstone10 on 6/22/16.
//  Copyright © 2016 DetroitLabs. All rights reserved.
//

#import "SecondViewController.h"
#import "VideoSource.h"
#import <opencv2/opencv.hpp>
#import "PatternDetector.h"

@interface SecondViewController () <VideoSourceDelegate>

@property (nonatomic, strong)VideoSource *videoSource;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end


@implementation SecondViewController

PatternDetector * m_detector;
NSTimer * m_trackingTimer;

UIView *indicator;

- (void)viewDidLoad {
	[super viewDidLoad];
	
	indicator = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 200, 10)];
	[indicator setBackgroundColor:[UIColor redColor]];
	[self.view addSubview:indicator];
	
	self.videoSource = [[VideoSource alloc] init];
	self.videoSource.delegate = self;
	[self.videoSource startWithDevicePosition:AVCaptureDevicePositionBack];
	
	//set up pattern tracking
	UIImage *imageToTrack = [UIImage imageNamed:@"target.jpg"];
	m_detector = new PatternDetector([self toCVMat:imageToTrack]);
	
	//start tracking timer
	m_trackingTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0f/20.0f) target:self selector:@selector(updateTracking:) userInfo:nil repeats:YES];
}

- (void)updateTracking:(NSTimer *)timer {
	if(m_detector->isTracking()) {
		NSLog(@"YES: %f", m_detector->matchValue());
		[indicator setBackgroundColor:[UIColor greenColor]];
	} else {
		NSLog(@"NO: %f", m_detector->matchValue());
		[indicator setBackgroundColor:[UIColor redColor]];
	}
}

- (void)frameReady:(VideoFrame)frame {
	__weak typeof(self) _weakSelf = self;
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		//make context ref from frame
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		CGContextRef newContext = CGBitmapContextCreate(frame.data, frame.width, frame.height, 8, frame.stride, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
		
		//make image ref from context ref
		CGImageRef newImage = CGBitmapContextCreateImage(newContext);
		CGContextRelease(newContext);
		CGColorSpaceRelease(colorSpace);
		
		//make UIImage from image ref
		UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation: UIImageOrientationRight];
		CGImageRelease(newImage);
		[[_weakSelf backgroundImageView] setImage:image];
	
	});
	
	//check each frame against our detector!
	m_detector->scanFrame(frame);
}

- (cv::Mat)toCVMat:(UIImage *)image {
	CGFloat cols = image.size.width;
	CGFloat rows = image.size.height;
	
	//create opencv image container, 8 bits per component, 4 channels
	cv::Mat cvMat(rows, cols, CV_8UC4);
	
	//create cg context adn draw the image
	CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], CGImageGetColorSpace(image.CGImage), kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);

	CGContextDrawImage(contextRef, CGRectMake(0,0,cols,rows), image.CGImage);
	CGContextRelease(contextRef);
	
	return cvMat;
}

- (UIImage *)fromCVMat:(const cv::Mat&)cvMat {
	CGColorSpaceRef colorSpace;
	if(cvMat.channels() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	
	CFDataRef data = CFDataCreate(kCFAllocatorDefault, cvMat.data, (cvMat.elemSize() * cvMat.total()));
	
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 8*cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
	
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CFRelease(data);
	CGColorSpaceRelease(colorSpace);
	
	return finalImage;
}

@end