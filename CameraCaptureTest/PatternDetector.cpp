//
//  PatternDetector.cpp
//  OpenCVTutorial
//
//  Created by Paul Sholtz on 12/14/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#include "PatternDetector.h"

//amount to scale the pattern image
const float kDefaultScaleFactor = 2.00f;
//confidence threshold for matching against the pattern (range from 0.0 to 1.0)
const float kDefaultThresholdValue = 0.40f;

PatternDetector::PatternDetector(const cv::Mat& patternImage) {
	m_patternImage = patternImage;
	
	//create the grayscale pattern image using appropriate conversions
	switch(patternImage.channels()) {
		case 4:
			cv::cvtColor(m_patternImage, m_patternImageGray, CV_RGBA2GRAY);
			break;
		case 3:
			cv::cvtColor(m_patternImage, m_patternImageGray, CV_RGB2GRAY);
			break;
		case 1:
			m_patternImageGray = m_patternImage;
			break;
	}
	
	//scale the gray image
	m_scaleFactor = kDefaultScaleFactor;
	float h = m_patternImageGray.rows / m_scaleFactor;
	float w = m_patternImageGray.cols / m_scaleFactor;
	cv::resize(m_patternImageGray, m_patternImageGrayScaled, cv::Size(w,h));
	
	//set up tracking parms
	m_matchThresholdValue = kDefaultThresholdValue;
	
	//CV_TM_CCOEFF_NORMED is one of six possible matching heuristics used by OpenCV
	// to compare images. With this heuristic, increasingly better matches are indicated
	// by increasingly largely numerical values (i.e., closer to 1.0).
	m_matchMethod = CV_TM_CCOEFF_NORMED;
}

void PatternDetector::scanFrame(VideoFrame frame) {
	//create grayscale query image from camera data
	cv::Mat queryImageGray, queryImageGrayScale;
	cv::Mat queryImage = cv::Mat(frame.height, frame.width, CV_8UC4, frame.data, frame.stride);
	cv::cvtColor(queryImage, queryImageGray, CV_BGR2GRAY);
	
	//scale it down
	float h = queryImageGray.rows / m_scaleFactor;
	float w = queryImageGray.cols / m_scaleFactor;
	cv::resize(queryImageGray, queryImageGrayScale, cv::Size(w,h));

	//run the matching algorithm
	int rows = queryImageGrayScale.rows - m_patternImageGrayScaled.rows + 1;
	int cols = queryImageGrayScale.cols - m_patternImageGrayScaled.cols + 1;
	
	//Since the type of resultImage is cv::Mat, the output array can be rendered on-screen
	//as a black-and-white image where brighter pixels indicate better match points between
	//the two images. This can be extremely useful when debugging.
	cv::Mat resultImage = cv::Mat(cols, rows, CV_32FC1);
	cv::matchTemplate(queryImageGrayScale, m_patternImageGrayScaled, resultImage, m_matchMethod);
	
	//find min/max
	double minVal, maxVal;
	cv::Point minLoc, maxLoc;
	//look at array of match results. determine the best match from the array of possibilities
	cv::minMaxLoc(resultImage, &minVal, &maxVal, &minLoc, &maxLoc, cv::Mat());
	switch(m_matchMethod) {
		case CV_TM_SQDIFF:
		case CV_TM_SQDIFF_NORMED:
			m_matchPoint = minLoc;
			m_matchValue = minVal;
			break;
		default:
			m_matchPoint = maxLoc;
			m_matchValue = maxVal;
			break;
	}
}

const cv::Point& PatternDetector::matchPoint() {
	return m_matchPoint;
}

float PatternDetector::matchValue() {
	return m_matchValue;
}

float PatternDetector::matchThresholdValue() {
	return m_matchThresholdValue;
}

bool PatternDetector::isTracking() {
	switch(m_matchMethod) {
		case CV_TM_SQDIFF:
		case CV_TM_SQDIFF_NORMED:
			return m_matchValue < m_matchThresholdValue;
		default:
			return m_matchValue > m_matchThresholdValue;
	}
}