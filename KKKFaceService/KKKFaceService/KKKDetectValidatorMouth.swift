//
//  KKKDetectValidatorMouth
//  KKKFaceService
//
//  Created by kkwong on 16/8/30.
//  Copyright © 2016年 kkwong. All rights reserved.
//

import Foundation

class KKKDetectValidatorMouth:KKKDetectStatusValidator{
    var minIndex:Int
    var maxIndex:Int
    var minMouthHeight:CGFloat
    var maxMouthHeight:CGFloat
    var validCounts:Int
    var validCountsMax:Int
    
    
    override func  isValid(detector:KKKDetector) -> Bool{
        self.checkCounts+=1

        let info:NSMutableDictionary = detector.lastMarkInfo.mutableCopy() as! NSMutableDictionary
        //需要两者的差值，X轴间距
        var pair:Array<String> = ["mouth_left_corner","mouth_right_corner"]
        self.addPair(info, key1: pair[0], key2: pair[1])
        
        var pairHeight:Array<String> = ["mouth_upper_lip_top","mouth_lower_lip_bottom"]
        self.addPair(info, key1: pairHeight[0], key2: pairHeight[1])
        let pairName = self.pairName(pairHeight[0], key2: pairHeight[1])
        let pairNameWidth = self.pairName(pair[0], key2: pair[1])
        let pairInfo:NSDictionary = info[pairName] as! NSDictionary
        //差值，X轴间距
        let deltaY:CGFloat = CGFloat((pairInfo.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
        if minMouthHeight == 0 {
            minMouthHeight = deltaY
        }

        let newMin:CGFloat =  min(deltaY, minMouthHeight)
        //更新差值最小值，X轴间距
        if newMin != minMouthHeight {
            minIndex = infoArray.count
            minMouthHeight = newMin
        }
        
        //更新差值最大值，X轴间距
        let newMax:CGFloat =  max(deltaY, maxMouthHeight)
        if newMax != maxMouthHeight {
            maxIndex = infoArray.count
            maxMouthHeight = newMax
        }
        
        self.infoArray.addObject(info)
        
        let widthToMatch = 15
        let heightToMatch = 15
        if (maxMouthHeight - minMouthHeight) > CGFloat(heightToMatch) {
            //设定嘴角横轴间距大于widthToMatch，且纵轴位置大于heightToMatch为张嘴
            let mouthWidthMin:Int = self.infoArray[minIndex][pairNameWidth]!![KCIFlyFaceResultPointX] as! Int
            let mouthWidthMax:Int = self.infoArray[maxIndex][pairNameWidth]!![KCIFlyFaceResultPointX] as! Int
            if ( mouthWidthMin - mouthWidthMax ) > widthToMatch
                {
                self.validCounts += 1
                    self.minIndex = 0
                    self.maxIndex = 0
                    self.minMouthHeight = 0
                    self.maxMouthHeight = 0
                    self.infoArray.removeAllObjects()
                    print("##✅张嘴通过第\(self.validCounts)次---\n嘴高:\(minMouthHeight)--\(maxMouthHeight) ----\n嘴宽 x:\(mouthWidthMin)-\(mouthWidthMax)")

                    
            }
        }
        
        if self.validCounts >= validCountsMax {
            //设定张嘴1次才算通过
            self.validateOK = true
        }
        
        if (self.validateOK == true) {
            //清空状态数据
            self.empty()
            //张嘴过程通过后，走摇头校验过程
            detector.status = .KKKFaceDetectStatusToShakeHead
            detector.statusValidator = KKKDetectValidatorHead()
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
        self.minMouthHeight = 0
        self.maxMouthHeight = 0
        self.validCounts = 0
        self.validCountsMax = 1
        super.init()
        self.checkCountsMax = 30*2
    }
    
    override func  empty() {
        self.validateOK = false
        self.minIndex = 0
        self.maxIndex = 0
        self.minMouthHeight = 0
        self.maxMouthHeight = 0
        self.validCounts = 0
        super.empty()
        
    }

}