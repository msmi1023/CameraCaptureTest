//
//  VideoSource.m
//  OpenCVTutorial
//
//  Created by Paul Sholtz on 12/14/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import "VideoSource.h"

#pragma mark -
#pragma mark VideoSource Class Extension
@interface VideoSource () <AVCaptureVideoDataOutputSampleBufferDelegate>

@end

#pragma mark -
#pragma mark VideoSource Implementation
@implementation VideoSource

#pragma mark -
#pragma mark Object Lifecycle
- (id)init {
    self = [super init];
    if ( self ) {
		AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
		
		if([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
			[captureSession setSessionPreset:AVCaptureSessionPreset640x480];

			NSLog(@"Capturing video at 640x480");
		} else {
			NSLog(@"Couldn't configure AVCaptureSession video input");
		}
		_captureSession = captureSession;
    }
    return self;
}

- (void)dealloc {
	[_captureSession stopRunning];
}

#pragma mark -
#pragma mark Public Interface
- (BOOL)startWithDevicePosition:(AVCaptureDevicePosition)devicePosition {
	
	// get camera device for the specified position
	AVCaptureDevice *videoDevice = [self cameraWithPosition:devicePosition];
	if(!videoDevice) {
		NSLog(@"Couldn't initialize camera at position %ld", (long)devicePosition);
	}
	
	//get camera device input port
	NSError *err;
	AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&err];
	
	if(!err) {
		[self setDeviceInput:videoInput];
	} else {
		NSLog(@"Could not open input port for device %@ (%@)", videoDevice, [err localizedDescription]);
		return FALSE;
	}
	
	//configure input port
	if([self.captureSession canAddInput:videoInput]) {
		[self.captureSession addInput:videoInput];
	} else {
		NSLog(@"Couldn't add input port to capture session %@", self.captureSession);
		return FALSE;
	}
	
	//configure output port
	[self addVideoDataOutput];
	
	//start running capture session
	[self.captureSession startRunning];
	
	return TRUE;
}

#pragma mark -
#pragma mark Helper Methods
- (AVCaptureDevice*)cameraWithPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for(AVCaptureDevice *device in devices) {
		if([device position] == position) {
			return device;
		}
	}
    return nil;
}

- (void)addVideoDataOutput {
    //create new video data output object
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	
	//sample buffer delegate requres serial dispatch queue
	dispatch_queue_t queue;
	queue = dispatch_queue_create("com.detroitlabs.CameraCaptureTest", DISPATCH_QUEUE_SERIAL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	//dispatch_release(queue);
	
	//define pixel format for output
	NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
	NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary *settings = @{key:value};
	[captureOutput setVideoSettings:settings];
	
	//configure output port on captureSession
	[self.captureSession addOutput:captureOutput];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
		didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection {
	//convert sample buffer to image buffer
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	//lock pixel buffer
	CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
	
	//construct VideoFrame struct
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
	VideoFrame frame = {width, height, stride, baseAddress};
	
	//give frame to VideoSource delegate
	[self.delegate frameReady:frame];
	
	//unlock pixel buffer
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
