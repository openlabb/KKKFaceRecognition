//
//  KKKDetectStatus.swift
//  KKKFaceService
//
//  Created by kkwong on 16/8/29.
//  Copyright © 2016年 kkwong. All rights reserved.
//

import Foundation

class KKKDetectStatusValidator:NSObject{
    var status:KKKFaceDetectStatus
    var validateOK:Bool?
    var checkCounts:Int
    var checkCountsMax:Int
    var imageHeight:CGFloat
    var imageWidth:CGFloat
    var isFrontCamera:Bool
    var infoArray:NSMutableArray

    required override init() {
        status = .KKKFaceDetectStatusWaiting
        checkCounts = 0
        checkCountsMax = 30*2
        imageHeight = 0
        imageWidth = 0
        isFrontCamera = true
        infoArray = []
        super.init()
    }
    
    func isValid(detector:KKKDetector) -> Bool{
        return true
    }
    
    //处理x,y点坐标映射
    func castXY(xyInfo:NSDictionary) -> NSDictionary {
        let attr1:NSDictionary = xyInfo
        let x1:CGFloat = CGFloat((attr1.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!)
        let y1:CGFloat = CGFloat((attr1.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
        
        var p:CGPoint = CGPointMake(y1, x1)
        if !isFrontCamera {
            p = pSwap(p)
            p = pRotate90(p, imageHeight, imageWidth)
        }
        return [KCIFlyFaceResultPointX:p.x,KCIFlyFaceResultPointY:p.y]
    }
    
    
    //添加需要取点距离的键值对
    func addPair(infoDic:NSDictionary,key1:String,key2:String){
        let yDeltaKeysToPair:Array = [key1,key2]
        let pairNewKey = pairName(yDeltaKeysToPair[0],key2: yDeltaKeysToPair[1])
        let pairNewValue = pairValue(infoDic, key1: yDeltaKeysToPair[0], key2: yDeltaKeysToPair[1])
        infoDic.setValue(pairNewValue, forKey: pairNewKey)
    }
    
    //取点距离的键值对新名字
    func pairName(key1:String,key2:String) -> String{
        return "\(key1)-\(key2)"
    }
    
    
    //取点距离的键值对对应的新坐标值
    func pairValue(infoDic:NSDictionary,key1:String,key2:String
        ) -> NSDictionary {
        let attr1:NSDictionary = castXY(infoDic[key1] as! NSDictionary)
        let attr2:NSDictionary = castXY(infoDic[key2] as! NSDictionary)
        let xDelta:CGFloat = abs(CGFloat((attr1.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!) - CGFloat((attr2.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!))
        
        let yDelta:CGFloat = abs( CGFloat((attr1.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!) - CGFloat((attr2.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!))
        return [KCIFlyFaceResultPointX:xDelta,KCIFlyFaceResultPointY:yDelta]
    }

    //清空状态和数据,设定每个阶段的校验次数额度,照片或许检验几万次能通过,但是活体只要几十次，以此来区分
    func empty() {
        self.infoArray.removeAllObjects()
        status = .KKKFaceDetectStatusWaiting
        checkCounts = 0
        checkCountsMax = 30*2
        imageHeight = 0
        imageWidth = 0
        isFrontCamera = true
    }

    
    func printInfoArray(){
        //该方法耗CPU，断点expression使用
        let itemArrayInfo:NSMutableDictionary = [:].mutableCopy() as! NSMutableDictionary
        let keyArray:Array<String> = (self.infoArray[0] as! NSDictionary).allKeys as! Array<String>
        for key in keyArray{
            let xArray = [].mutableCopy()
            let yArray = [].mutableCopy()
            let xyInfo = [KCIFlyFaceResultPointX:xArray,KCIFlyFaceResultPointY:yArray]
            itemArrayInfo.setObject(xyInfo, forKey: key)
        }
        
        for index in 0...self.infoArray.count-1 {
            let item:Dictionary<String,Dictionary<String,Int>> =  self.infoArray[index] as! Dictionary<String,Dictionary<String,Int>>
            for key in keyArray {
                var xyInfo:Dictionary<String,Int> = item[key]! as Dictionary<String,Int>


                var mInfo:Dictionary<String,Array<Int>> = itemArrayInfo[key] as! Dictionary<String,Array<Int>>
                var xArray:Array<Int> = mInfo[KCIFlyFaceResultPointX]! as Array<Int>
                var yArray:Array<Int> = mInfo[KCIFlyFaceResultPointY]! as Array<Int>
                xArray.append(xyInfo[KCIFlyFaceResultPointX]!)
                yArray.append(xyInfo[KCIFlyFaceResultPointY]!)
                mInfo[KCIFlyFaceResultPointX] = xArray
                mInfo[KCIFlyFaceResultPointY] = yArray
                itemArrayInfo.setObject(mInfo, forKey: key)
            }
            
        }
        print("🚼--\(itemArrayInfo)")

    }

    
}


