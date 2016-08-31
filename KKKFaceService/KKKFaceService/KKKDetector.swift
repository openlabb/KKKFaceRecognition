//
//  KKKFaceDetector.swift
//  KKKFaceService
//
//  Created by kkwong on 16/8/30.
//  Copyright © 2016年 kkwong. All rights reserved.
//

import Foundation

public enum KKKFaceDetectStatus:Int {
    case KKKFaceDetectStatusWaiting
    case KKKFaceDetectStatusTooFar
    case KKKFaceDetectStatusTooClose
    case KKKFaceDetectStatusToAdjustFace
    case KKKFaceDetectStatusToBlinkEye
    case KKKFaceDetectStatusToOpenMouth
    case KKKFaceDetectStatusToShakeHead
    case KKKFaceDetectStatusToRequest
    case KKKFaceDetectStatusRegisterFail
    case KKKFaceDetectStatusRegisterSuccess
    case KKKFaceDetectStatusRecognitionFail
    case KKKFaceDetectStatusRecognitionSuccess
    case KKKFaceDetectStatusNone
}


class KKKDetector:NSObject{
    var status:KKKFaceDetectStatus
    var statusValidator:KKKDetectStatusValidator
    var lastMarkInfo:NSDictionary
    var lastImageHeight:CGFloat
    var lastImageWidth:CGFloat
    var lastTimestamp:NSTimeInterval
    var maxTimeduration:NSTimeInterval
    var isFrontCamera:Bool
    
    
    
    required override init() {
        status = .KKKFaceDetectStatusWaiting
        lastMarkInfo = [:]
        lastImageWidth = 0
        lastImageHeight = 0
        statusValidator = KKKDetectStatusValidator()
        lastTimestamp = NSDate().timeIntervalSince1970
        maxTimeduration = 10
        isFrontCamera = true
        super.init()
    }
    
    func empty()  {
        status = .KKKFaceDetectStatusWaiting
        lastMarkInfo = [:]
        lastImageWidth = 0
        lastImageHeight = 0
        statusValidator.empty()
        statusValidator = KKKDetectStatusValidator()
        lastTimestamp = NSDate().timeIntervalSince1970
        
    }
    
    func checkFaceValid(left:CGFloat,right:CGFloat,top:CGFloat,bottom:CGFloat) -> Bool {
        
        let xDeltaMax:CGFloat = 320
        let xDeltaMin:CGFloat = 240
        let xDelta:CGFloat = right - left
        
        let yDeltaMax:CGFloat = 320
        let yDeltaMin:CGFloat = 240
        let yDelta:CGFloat = bottom - top
        
        var ret:Bool = false
        
        if (xDelta < xDeltaMin || yDelta < yDeltaMin){
            status = .KKKFaceDetectStatusTooFar
        }else if (xDelta > xDeltaMax || yDelta > yDeltaMax){
            status = .KKKFaceDetectStatusTooClose
        }else{
            if ( NSDate().timeIntervalSince1970 - self.lastTimestamp > self.maxTimeduration) {
                empty()
            }
            if status.rawValue < 4  {
                status = .KKKFaceDetectStatusToBlinkEye
                statusValidator = KKKDetectValidatorEye()
                statusValidator = KKKDetectValidatorEye()
                statusValidator.imageHeight = self.lastImageHeight
                statusValidator.imageWidth = self.lastImageWidth
                statusValidator.isFrontCamera = self.isFrontCamera
            }
            
            if status == .KKKFaceDetectStatusToRequest {
                //去执行
            }
            ret = true
        }
        
        return ret
    }
    
    func checkStatus(landmarkDic:NSDictionary,imgHeight:CGFloat,imgWidth:CGFloat) -> Bool{
        if self.status.rawValue < 4 {
            return false
        }
        lastImageHeight = imgHeight
        lastImageWidth = imgWidth
        lastMarkInfo = landmarkDic
        return statusValidator.isValid(self)
    }
    
    
}
