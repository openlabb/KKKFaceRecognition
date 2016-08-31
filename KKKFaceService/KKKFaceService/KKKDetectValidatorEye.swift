//
//  KKKDetectValidatorEye.swift
//  KKKFaceService
//
//  Created by kkwong on 16/8/30.
//  Copyright © 2016年 kkwong. All rights reserved.
//

import Foundation

class KKKDetectValidatorEye:KKKDetectStatusValidator{
    var minIndex:Int
    var maxIndex:Int
    var minYDetalLeft:CGFloat
    var maxYDetalLeft:CGFloat
    var validCounts:Int
    var validCountsMax:Int
    
    
    /*判断是否活体眨眼，需要满足下面设定：
      1,眉眼Y轴间距大于pairDeltaToMatch
      2,眉眼Y轴间距大于pairDeltaToMatch时，鼻子间距小于noseDletaToMatch
      3,检测次数不超过checkCountsMax次，太多有照片而非活体的嫌疑
      4,累计满足1,2,3条件validCountsMax次
    */
    override func  isValid(detector:KKKDetector) -> Bool{
        self.checkCounts+=1
        let info:NSMutableDictionary = detector.lastMarkInfo.mutableCopy() as! NSMutableDictionary
        //需要两者的差值，Y轴间距
        var pair:Array<String> = ["left_eye_center","left_eyebrow_middle"]
        self.addPair(info, key1: pair[0], key2: pair[1])
        let pairName = self.pairName(pair[0], key2: pair[1])
        let pairInfo:NSDictionary = info[pairName] as! NSDictionary
        //差值，Y轴间距
        let deltaY:CGFloat = CGFloat((pairInfo.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
        if minYDetalLeft == 0 {
            minYDetalLeft = deltaY
        }
        
        let newMin:CGFloat =  min(deltaY, minYDetalLeft)
        //更新差值最小值，Y轴间距
        
        if minYDetalLeft > 0 && newMin != minYDetalLeft {
            minIndex = infoArray.count
            minYDetalLeft = newMin
        }

        //更新差值最大值，Y轴间距
        let newMax:CGFloat =  max(deltaY, maxYDetalLeft)
        if newMax != maxYDetalLeft {
            maxIndex = infoArray.count
            maxYDetalLeft = newMax
        }
        
        self.infoArray.addObject(info)
        
        //看看最大值最小值时候鼻子的变化，避免拿个图片晃啊晃来假装
        let pairDeltaToMatch = 6
        let noseDletaToMatch = 3
        if (maxYDetalLeft - minYDetalLeft) > CGFloat(pairDeltaToMatch) {
            //设定眉眼间距大于10，且鼻子位置不动为眨眼
            let mouthKey:String = "mouth_middle"
            let mouthXMin = self.infoArray[minIndex][mouthKey]!![KCIFlyFaceResultPointX] as! Int
            let mouthXMax = self.infoArray[maxIndex][mouthKey]!![KCIFlyFaceResultPointX] as! Int
            let mouthYMin = self.infoArray[minIndex][mouthKey]!![KCIFlyFaceResultPointY] as! Int
            let mouthYMax = self.infoArray[maxIndex][mouthKey]!![KCIFlyFaceResultPointY] as! Int
            if (mouthYMax - mouthYMin) < noseDletaToMatch
            && (mouthXMax - mouthXMin) < noseDletaToMatch {
                self.validCounts += 1
                self.minIndex = 0
                self.maxIndex = 0
                self.minYDetalLeft = 0
                self.maxYDetalLeft = 0
                self.infoArray.removeAllObjects()
                print("#✅眨眼通过第\(self.validCounts)次---\n眉眼距离:\(minYDetalLeft)--\(maxYDetalLeft) ----\n鼻子 x:\(mouthXMax)-\(mouthXMin) y:\(mouthYMax)-\(mouthYMin)")
            }
        }
        
//        self.printInfoArray()
        
        if self.validCounts >= validCountsMax {
            //设定眨眼两次才算通过
            self.validateOK = true
        }
        
        if (self.validateOK == true) {
            //清空状态数据
            self.empty()
            //眨眼过程通过后，走张嘴校验过程
            detector.status = .KKKFaceDetectStatusToOpenMouth
            detector.statusValidator = KKKDetectValidatorMouth()
            detector.statusValidator.imageHeight = detector.lastImageHeight
            detector.statusValidator.imageWidth = detector.lastImageWidth
            detector.statusValidator.isFrontCamera = detector.isFrontCamera
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
        self.minYDetalLeft = 0
        self.maxYDetalLeft = 0
        self.validCounts = 0
        self.validCountsMax = 1
        super.init()
        self.checkCountsMax = 30*2
    }
    
    override func  empty() {
        self.minIndex = 0
        self.maxIndex = 0
        self.minYDetalLeft = 0
        self.maxYDetalLeft = 0
        self.validCounts = 0
        super.empty()
        
    }
    
}