//
//  KKKDetectValidatorHead
//  KKKFaceService
//
//  Created by kkwong on 16/8/30.
//  Copyright © 2016年 kkwong. All rights reserved.
//

import Foundation

class KKKDetectValidatorHead:KKKDetectStatusValidator{
    var minMouthX:CGFloat
    var maxMouthX:CGFloat
    var minIndex:Int
    var maxIndex:Int
    var validCounts:Int
    var validCountsMax:Int
    
    override func  isValid(detector:KKKDetector) -> Bool{
        self.checkCounts+=1

        let info:NSMutableDictionary = detector.lastMarkInfo.mutableCopy() as! NSMutableDictionary
        let keyItem:NSDictionary = info["mouth_middle"] as! NSDictionary
        
        let currentX:CGFloat = CGFloat((keyItem.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!)
        if 0 == minMouthX {
            minMouthX = currentX
        }
        let newMin:CGFloat =  min(currentX, minMouthX)
        //更新差值最小值
        if newMin != minMouthX {
            minIndex = infoArray.count
            minMouthX = newMin
        }
        
        //更新差值最大值
        let newMax:CGFloat =  max(currentX, maxMouthX)
        if newMax != maxMouthX {
            maxIndex = infoArray.count
            maxMouthX = newMax
        }
        
        self.infoArray.addObject(info)
        
        let widthToMatch = 8
        if (maxMouthX - minMouthX) > CGFloat(widthToMatch) {
            self.validCounts += 1
            self.minIndex = 0
            self.maxIndex = 0
            self.minMouthX = 0
            self.maxMouthX = 0
            self.infoArray.removeAllObjects()
            print("###✅摇头通过第\(self.validCounts)次---\n嘴巴:\(minMouthX)--\(maxMouthX) ")

        }
        
//        print("###摇头通过第\(self.checkCounts)次---\n鼻子:\(minMouthX)--\(maxMouthX) ")

        
        if self.validCounts >= validCountsMax {
            self.validateOK = true
        }
        
        if (self.validateOK == true) {
            //清空状态数据
            self.empty()
            
            //摇头过程通过后，走远程识别过程
            detector.status = .KKKFaceDetectStatusToRequest
//            detector.statusValidator = nil
//            detector.statusValidator.imageHeight = detector.lastImageHeight
//            detector.statusValidator.imageWidth = detector.lastImageWidth
//            detector.statusValidator.isFrontCamera = detector.isFrontCamera
            
            return true
        }
        
        if self.checkCounts > self.checkCountsMax {
            //本次测试太多次了 约1秒30次 默认2秒
            self.empty()
        }
        return false
    }
    
    required init() {
        self.minIndex = 0
        self.maxIndex = 0
        self.minMouthX = 0
        self.maxMouthX = 0
        self.validCounts = 0
        self.validCountsMax = 1
        super.init()
        self.checkCountsMax = 30*2
    }
    
    override func  empty() {
        self.minIndex = 0
        self.maxIndex = 0
        self.minMouthX = 0
        self.maxMouthX = 0
        self.validCounts = 0
        super.empty()
        
    }

}