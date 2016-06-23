//
//  PatternDetector.h
//  OpenCVTutorial
//
//  Created by Paul Sholtz on 12/14/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#ifndef __CameraCaptureTest__PatternDetector__
#define __CameraCaptureTest__PatternDetector__

#include "VideoFrame.h"
#import <opencv2/opencv.hpp>

class PatternDetector
{
public:
	//constructor
	PatternDetector(const cv::Mat& pattern);
	
	//scan the input video frame
	//going to run this thing hopefully at parity with video framerate
	void scanFrame(VideoFrame frame);
	
	//matching api functions
	const cv::Point& matchPoint();
	float matchValue();
	float matchThresholdValue();
	
	//tracking api
	bool isTracking();
	
private:
	//reference marker images
	cv::Mat m_patternImage;
	cv::Mat m_patternImageGray;
	cv::Mat m_patternImageGrayScaled;
	
	//supporting members
	cv::Point m_matchPoint;
	int m_matchMethod;
	float m_matchValue;
	float m_matchThresholdValue;
	float m_scaleFactor;
};

#endif /* defined(__CameraCaptureTest__PatternDetector__) */
