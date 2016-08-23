//
//  CaptureManager.h
//  IFlyFaceDemo
//
//  Created by 张剑 on 15/7/10.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CaptureContextType){
    CaptureContextTypeRunningAndDeviceAuthorized,
    CaptureContextTypeCameraFrontOrBackToggle
};

@class IFlyFaceImage;

@protocol CaptureManagerDelegate <NSObject>

@optional


-(void)onOutputFaceImage:(IFlyFaceImage*)img;
-(void)observerContext:(CaptureContextType)type Changed:(BOOL)boolValue;

@end


@interface CaptureManager : NSObject

// delegate
@property (nonatomic) id<CaptureManagerDelegate> delegate;

// Device orientation
@property (nonatomic) CMMotionManager *motionManager;


// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;

@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;

@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;

@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;


// init CaptureSessionManager functions
- (void)setup;
- (void)teardown;
- (void)addObserver;
- (void)removeObserver;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;


// functions
- (void)cameraToggle;
+ (AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation;

@end
