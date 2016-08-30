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
    var maxTimeduration:NSInteger
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
            if (lastTimestamp - NSDate().timeIntervalSince1970) > 10 {
                empty()
            }
            if status.rawValue < 4  {
                status = .KKKFaceDetectStatusToBlinkEye
                statusValidator = KKKDetectValidatorEye()

            }
            statusValidator = KKKDetectValidatorEye()
            statusValidator.imageHeight = self.lastImageHeight
            statusValidator.imageWidth = self.lastImageWidth
            statusValidator.isFrontCamera = self.isFrontCamera

            ret = true
            
//            if statusValidator .isKindOfClass(<#T##aClass: AnyClass##AnyClass#>) {
//                <#code#>
//            }
            
            
//            if isEyeValid == false && isMouthValid == false && isShakingValide == false{
//                detectStatus =  .KKKFaceDetectStatusToBlinkEye
//            }
//            else if isEyeValid == true && isMouthValid == false && isShakingValide == false{
//                //1－脸部大小size满足✅,2－张嘴条件未满足❎
//                detectStatus =  .KKKFaceDetectStatusToOpenMouth
//            }else if isEyeValid == true && isMouthValid == true && isShakingValide == false{
//                //2－张嘴条件满足✅,3－摇头条件未满足❎
//                detectStatus =  .KKKFaceDetectStatusToShakeHead
//                mouthOpenedCounts = 0
//            }else if isMouthValid == true &&  isShakingValide == true && isEyeValid == true{
//                //3－摇头条件满足✅,4- 去在线注册或者识别吧
//                detectStatus =  .KKKFaceDetectStatusToRequest
//                
//                if detectStatus == .KKKFaceDetectStatusToRequest {
//                    showStatus()
//                    if ((self.captureManager?.session.running) == true){
//                        self.previewLayer?.session.stopRunning()
//                    }
//                    //                    self.performSelector(#selector(doCapturePhoto), withObject: nil, afterDelay: 1)
//                    self.performSelector(#selector(doFaceRequest), withObject: nil, afterDelay: 0.1
//                    )
//                }
//                
//            }
        }
//
        
        return ret
    }
    
    func checkStatus(landmarkDic:NSDictionary,imgHeight:CGFloat,imgWidth:CGFloat) -> Bool{
        lastImageHeight = imgHeight
        lastImageWidth = imgWidth
        lastMarkInfo = landmarkDic
        return statusValidator.isValid(self)
    }
    
    
}
