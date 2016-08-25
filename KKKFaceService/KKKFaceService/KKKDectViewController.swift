//
//  KKKDectViewController.swift
//  KKKFaceService
//
//  Created by kkwong on 16/8/18.
//  Copyright © 2016年 kkwong. All rights reserved.
//

import UIKit
import QuartzCore
import ImageIO

public let kIFlyAPPID = "57a454e5"


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
    case KKKFaceDetectStatusNone}

class KKKDectViewController: UIViewController,IFlyFaceRequestDelegate,CaptureManagerDelegate {
    
    @IBOutlet weak var referFaceView: UIView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var testkkView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var isRegister:Bool
    
    var captureManager:CaptureManager?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var viewCanvas:CanvasView?
    var faceDetector:IFlyFaceDetector?
    var stillImageOutput:AVCaptureStillImageOutput?

    var totalFaceCounts:Int
    
    var eyeLeftCornerYLast:Int
    var eyeLeftOpenedCounts:Int
    var eyeLeftYLast:Int
    var eyeRightCornerYLast:Int
    var eyeRightYLast:Int
    var eyeMouthYLast:Int
    var eyeMouthXLast:Int


    var mouthWidthLast:Int
    var mouthHeightLast:Int
    var mouthOpenedCounts:Int
    
    
    var noseX:Int
    var noseXLeft:Int
    var noseXRight:Int
    
    var isSizeValid:Bool
    var isEyeValid:Bool
    var isMouthValid:Bool
    var isShakingValide:Bool
    var resultStrings:String?
    var faceGID:String?
    var faceScore:String?
    var iFlySpFaceRequest: IFlyFaceRequest?
    
    var detectStatus:KKKFaceDetectStatus?
//    var detectStatus:KKKFaceDetectStatus?{
//        didSet{
//            showStatus()
//        }
//    }
    
    //MARK: ----Life cycle
    
    required init?(coder aDecoder: NSCoder) {
        self.totalFaceCounts = 0
        
        self.eyeLeftCornerYLast = 0
        self.eyeRightCornerYLast = 0
        self.eyeLeftOpenedCounts = 0
        self.eyeLeftYLast = 0
        self.eyeRightYLast = 0
        self.eyeMouthYLast = 0
        self.eyeMouthXLast = 0
        
        self.mouthWidthLast = 0
        self.mouthHeightLast = 0
        self.mouthOpenedCounts = 0

        self.noseX = 0
        self.noseXLeft = 0
        self.noseXRight = 0
        
        self.isSizeValid = false
        self.isMouthValid = false
        self.isEyeValid = false
        self.isShakingValide = false
        self.detectStatus = .KKKFaceDetectStatusWaiting

        self.resultStrings = ""
        self.isRegister = true
        super.init(coder: aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.title = "活体人脸识别"
        self.edgesForExtendedLayout = .None;
        self.extendedLayoutIncludesOpaqueBars = false;
        self.modalPresentationCapturesStatusBarAppearance = false;
        self.navigationController!.navigationBar.translucent = false;
        
        self.view.backgroundColor = UIColor.blackColor()

        self.configSubViews()
        
        self.loadConfigData()
    }

    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.captureManager?.removeObserver()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func addCanvas() -> Void {
        self.viewCanvas = CanvasView(frame: self.captureManager!.previewLayer.frame)
        self.viewCanvas?.center = self.captureManager!.previewLayer.position
        self.viewCanvas?.backgroundColor = UIColor.clearColor()
        self.previewView.addSubview(self.viewCanvas!)
        self.previewView.bringSubviewToFront(self.referFaceView)
        self.referFaceView.backgroundColor = UIColor.clearColor()
        self.referFaceView.layer.borderColor = UIColor.orangeColor().CGColor
        self.referFaceView.layer.borderWidth = 2
    }
    
    func addPrewLayer() -> Void {
        self.previewView.backgroundColor = UIColor.blackColor()
        self.faceDetector=IFlyFaceDetector.sharedInstance();
        self.faceDetector?.setParameter("1", forKey: "align")
        self.faceDetector?.setParameter("1", forKey: "detect")
        
        self.captureManager = CaptureManager()
        self.captureManager!.delegate = self
        self.previewLayer = self.captureManager!.previewLayer
        
        self.captureManager!.previewLayer.frame = self.previewView!.frame
        self.captureManager!.previewLayer.position = self.previewView!.center
        self.captureManager!.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        [self.previewView.layer.addSublayer(self.captureManager!.previewLayer)]
    }
    
    func addStillImageOutput() -> Void {
        let imgOutputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = imgOutputSettings
        captureManager?.session .addOutput(stillImageOutput)
    }
    
    func configSubViews() -> Void {
        self.addPrewLayer()
        self.addCanvas()
        self.addStillImageOutput()
        self.captureManager?.setup()
        self.captureManager?.addObserver()
        self.addRightBarAction()
    }
    
    func addLeftBarAction() -> Void {
        let item = UIBarButtonItem(title: "重新识别", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(refreshRecognition))
        self.navigationItem.leftBarButtonItem = item
        self.isRegister = false
    }

    func refreshRecognition() -> Void {
        self.navigationItem.rightBarButtonItem = nil
        self.clear()
        self.previewLayer?.session.startRunning()
    }
    
    func addRightBarAction() -> Void {
        let item = UIBarButtonItem(title: "注册", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(deleteFaceGID))
        self.navigationItem.rightBarButtonItem = item
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        self.captureManager?.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }
    
    
    
    //MARK: ----CaptureManagerDelegate
    func onOutputFaceImage(img: IFlyFaceImage!) {
        let strResult:NSString? = self.faceDetector?.trackFrame(img!.data, withWidth: Int32(img!.width), height: Int32(img!.height), direction: Int32(img!.direction.rawValue))
        
        //        img.data = nil
        
        if strResult == nil{
            return
        }

        let stringAndData:NSArray = [strResult!,img]
        
        self.performSelectorOnMainThread(#selector(parseResult), withObject: stringAndData, waitUntilDone: false)
    }
    
    
    
    
    func isFaceSizeValid(left:CGFloat,right:CGFloat,top:CGFloat,bottom:CGFloat) -> Bool {
        self.isSizeValid = false
        let xDeltaMax:CGFloat = 320
        let xDeltaMin:CGFloat = 240
        let xDelta:CGFloat = right - left
        
        let yDeltaMax:CGFloat = 320
        let yDeltaMin:CGFloat = 240
        let yDelta:CGFloat = bottom - top
        
        var ret:Bool = false
        
        if (xDelta < xDeltaMin || yDelta < yDeltaMin){
            detectStatus = .KKKFaceDetectStatusTooFar
        }else if (xDelta > xDeltaMax || yDelta > yDeltaMax){
            detectStatus = .KKKFaceDetectStatusTooClose
        }else{
            self.isSizeValid = true
            ret = true
            if isEyeValid == false && isMouthValid == false && isShakingValide == false{
                detectStatus =  .KKKFaceDetectStatusToBlinkEye
            }
            else if isEyeValid == true && isMouthValid == false && isShakingValide == false{
                //1－脸部大小size满足✅,2－张嘴条件未满足❎
                detectStatus =  .KKKFaceDetectStatusToOpenMouth
//                if (left < 100 || top < 100 || right > 460 || bottom > 400) {
//                    detectStatus =  .KKKFaceDetectStatusToAdjustFace
//                    clear()
//                    ret = true
//                }else{
//                    detectStatus =  .KKKFaceDetectStatusToOpenMouth
//                    ret = true
//                }
            }else if isEyeValid == true && isMouthValid == true && isShakingValide == false{
                //2－张嘴条件满足✅,3－摇头条件未满足❎
                detectStatus =  .KKKFaceDetectStatusToShakeHead
                mouthOpenedCounts = 0
            }else if isMouthValid == true &&  isShakingValide == true && isEyeValid == true{
                //3－摇头条件满足✅,4- 去在线注册或者识别吧
                detectStatus =  .KKKFaceDetectStatusToRequest
                
                if detectStatus == .KKKFaceDetectStatusToRequest {
                    showStatus()
                    if ((self.captureManager?.session.running) == true){
                        self.previewLayer?.session.stopRunning()
                    }
//                    self.performSelector(#selector(doCapturePhoto), withObject: nil, afterDelay: 1)
                    self.performSelector(#selector(doFaceRequest), withObject: nil, afterDelay: 0.1
                    )
                }

            }
        }
        
        showStatus()
        guard ret else{
            self.clear()
            return false
        }
        return true
    }
    
    func isFaceEyeValid(landmarkDic:NSDictionary?,imgHeight:CGFloat,imgWidth:CGFloat) -> Bool {
        if isEyeValid {
            return true
        }
        
        var eyeLeftY:Int = 0
        var eyeLeftCornerY:Int = 0
        var eyeRightCornerY:Int = 0
        var eyeMouthY:Int = 0
        var eyeMouthX:Int = 0
        
        
        let isFrontCamera = self.captureManager?.videoDeviceInput.device.position == .Front;
        
        
        let keys = landmarkDic!.keyEnumerator()
        for keyItem in keys {
            let key:String = keyItem as! String
            let attr = landmarkDic!.objectForKey(key)
            let x:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!)
            let y:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
            
            var p:CGPoint = CGPointMake(y, x)
            if !isFrontCamera {
                p = pSwap(p)
                p = pRotate90(p, imgHeight, imgWidth)
            }
            
            if key == "left_eye_center" {
                eyeLeftY = Int(p.y)
            }
            if key == "left_eye_left_corner" {
                eyeLeftCornerY = Int(p.y)
            }
            if key == "left_eye_right_corner" {
                eyeRightCornerY = Int(p.y)
            }
            if key == "nose_top" {
                eyeMouthY = Int(p.y)
                eyeMouthX = Int(p.x)

            }



            
            
        }
        
        let dateFormatter:NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyyMMddHHmmss";
        let dateString:String = dateFormatter.stringFromDate(NSDate())
        
        print("\(dateString)----眨眼前:\(eyeLeftYLast),\(eyeLeftCornerYLast),\(eyeRightCornerYLast),\(eyeMouthXLast),\(eyeMouthYLast)")
        
        print("\(eyeLeftOpenedCounts)----眨眼后:\(eyeLeftY),\(eyeLeftCornerY),\(eyeRightCornerY),\(eyeMouthX),\(eyeMouthY)")
        if eyeLeftYLast>0 && eyeLeftY>0 {
            //眼镜变化 嘴巴不动
            if (abs(eyeLeftY - eyeLeftYLast) >= 5
                && abs(eyeLeftCornerY - eyeLeftCornerYLast)>=2
                && abs(eyeRightCornerY - eyeRightCornerYLast)>=2
                && abs(eyeMouthX - eyeMouthXLast)<5
                && abs(eyeMouthY - eyeMouthYLast)<10 ) {
                eyeLeftOpenedCounts += 1
                
                if eyeLeftOpenedCounts > 1 {
                    isEyeValid = true
                }
                print(" ✅ 1.检测到眨眼 -----\n")
                return true
            }
        }
        
        if eyeLeftY>0 && isEyeValid==false {
            if eyeLeftOpenedCounts == 0 || eyeLeftOpenedCounts == 300 || eyeLeftOpenedCounts == 600  {
                //每隔10s算一个点
                eyeLeftYLast = eyeLeftY
                eyeLeftCornerYLast = eyeLeftCornerY
                eyeRightCornerYLast = eyeRightCornerY
                eyeMouthXLast = eyeMouthX
                eyeMouthYLast = eyeMouthY
            }else if(eyeLeftOpenedCounts == 1200){
                clear()
            }
            
        }
        
        return false
    }
    
    func isFaceMouthOpen(landmarkDic:NSDictionary?,imgHeight:CGFloat,imgWidth:CGFloat) -> Bool {
        if isEyeValid == false  {
            return false
        }
        
        if isMouthValid {
            return true
        }
        
        var mouthYTop:Int = 0
        var mouthYBottom:Int = 0
        var mouthXLeft:Int = 0
        var mouthXRight:Int = 0
        
        let isFrontCamera = self.captureManager?.videoDeviceInput.device.position == .Front;

        let keys = landmarkDic!.keyEnumerator()
        for keyItem in keys {
            let key:String = keyItem as! String
            let attr = landmarkDic!.objectForKey(key)
            let x:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!)
            let y:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
            
            var p:CGPoint = CGPointMake(y, x)
            if !isFrontCamera {
                p = pSwap(p)
                p = pRotate90(p, imgHeight, imgWidth)
            }
            
            if key == "mouth_upper_lip_top" {
                mouthYTop = Int(p.y)
            }else if key == "mouth_lower_lip_bottom"{
                mouthYBottom = Int(p.y)
            }else if key == "mouth_left_corner"{
                mouthXLeft = Int(p.x)
            }else if key == "mouth_right_corner"{
                mouthXRight = Int(p.x)
            }
            
            if mouthXLeft>0 && mouthXRight>0 && mouthYTop>0 && mouthYBottom>0{
                break
            }

        }
        
        let mouthWidth:Int = abs(mouthXRight - mouthXLeft)
        let mouthHeight:Int = abs(mouthYBottom - mouthYTop)
        
        let dateFormatter:NSDateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "yyyyMMddHHmmss";
        let dateString:String = dateFormatter.stringFromDate(NSDate())
        
        print("\(dateString)----张嘴前:\(mouthWidthLast),\(mouthHeightLast)")
        print("\(mouthOpenedCounts)----张嘴后:\(mouthWidth),\(mouthHeight)")
        if mouthWidthLast>0 && mouthWidth>0 {
            if (abs(mouthHeight - mouthHeightLast) >= 15 && abs(mouthWidthLast - mouthWidth) >= 15) {
                isMouthValid = true
                print(" ✅ 2.检测到张嘴 -----\n")
                return true
            }
        }

        if mouthXLeft>0 && mouthXRight>0 && mouthYTop>0 && mouthYBottom>0 && isMouthValid==false {
            if mouthOpenedCounts == 0 || mouthOpenedCounts == 300 || mouthOpenedCounts == 600  {
                mouthWidthLast =  abs(mouthXRight - mouthXLeft)
                mouthHeightLast =  abs(mouthYBottom - mouthYTop)
                mouthOpenedCounts += 1
            }else if(mouthOpenedCounts == 1200){
                clear()
            }
        }

        return false
    }

    func isFaceHeadShake(landmarkDic:NSDictionary?,imgHeight:CGFloat,imgWidth:CGFloat) -> Bool {
        guard isMouthValid else{
            return false
        }
        
        if isShakingValide{
            return true
        }
        
        let isFrontCamera = self.captureManager?.videoDeviceInput.device.position == .Front;
        
        let keys = landmarkDic!.keyEnumerator()
        for keyItem in keys {
            let key:String = keyItem as! String
            let attr = landmarkDic!.objectForKey(key)
            let x:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!)
            let y:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
            
            var p:CGPoint = CGPointMake(y, x)
            if !isFrontCamera {
                p = pSwap(p)
                p = pRotate90(p, imgHeight, imgWidth)
            }
            
            if key == "mouth_middle" && isMouthValid == true {
                if noseXRight == 0 {
                    noseXRight = Int(p.x)
                    noseXLeft = Int(p.x)
                }else if(Int(p.x) > noseXRight){
                    noseXRight = Int(p.x)
                }else if(Int(p.x) < noseXLeft){
                    noseXLeft = Int(p.x)
                }
                
                if  noseXRight - noseXLeft > 60 {
                    isShakingValide = true
                    print(" ✅ 3.检测到摇头 -----\n")
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func parseDetect(positionDic:NSDictionary,faceImg:IFlyFaceImage) -> NSString? {
        guard (positionDic.allKeys.count>0) else{
            return ""
        }
        
        let isFrontCamera = self.captureManager?.videoDeviceInput.device.position == .Front;
        
        let widthScaleBy:CGFloat = (self.previewLayer?.frame.size.width)! / faceImg.height
        let heightScaleBy:CGFloat = (self.previewLayer?.frame.size.height)! / faceImg.width
        
        let bottom:CGFloat = CGFloat((positionDic.objectForKey(KCIFlyFaceResultBottom)!.floatValue)!)
        let top:CGFloat = CGFloat((positionDic.objectForKey(KCIFlyFaceResultTop)!.floatValue)!)
        let left:CGFloat = CGFloat((positionDic.objectForKey(KCIFlyFaceResultLeft)!.floatValue)!)
        let right:CGFloat = CGFloat(positionDic.objectForKey(KCIFlyFaceResultRight)!.floatValue)
        
        let cx:CGFloat = (left+right)/2
        let cy:CGFloat = (top + bottom)/2
        let w:CGFloat = right - left
        let h:CGFloat = bottom - top
        
        let ncx:CGFloat = CGFloat(cy)
        let ncy:CGFloat = CGFloat(cx)
        
        var rectFace:CGRect = CGRectMake(ncx - w/2, ncy - w/2, w, h)
        
        if !isFrontCamera {
            rectFace = rSwap(rectFace)
            rectFace = rRotate90(rectFace, faceImg.height, faceImg.width)
        }
        
        let isFaceOK:Bool = self.isFaceSizeValid(left, right: right, top: top, bottom: bottom)
        
        
        
        guard isFaceOK else{
            return nil
        }
        
        print(" ✅ 1.检测到合格Size的人脸 -----\n")

        
        rectFace = rScale(rectFace, widthScaleBy, heightScaleBy)
        return  NSStringFromCGRect(rectFace)
    }
    
    func parseAlign(landmarkDic:NSDictionary?,orignImage faceImg:IFlyFaceImage) -> NSMutableArray? {
        if landmarkDic == nil {
            return[]
        }
        
        let isFrontCamera = self.captureManager?.videoDeviceInput.device.position == .Front;
        
        let widthScaleBy:CGFloat = (self.previewLayer?.frame.size.width)! / faceImg.height
        let heightScaleBy:CGFloat = (self.previewLayer?.frame.size.height)! / faceImg.width
        
        let arrStrPoints:NSMutableArray = []
        let keys = landmarkDic!.keyEnumerator()
        
        for key in keys {
            let attr = landmarkDic!.objectForKey(key)
            let x:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointX)?.floatValue)!)
            let y:CGFloat = CGFloat((attr?.objectForKey(KCIFlyFaceResultPointY)?.floatValue)!)
            
            var p:CGPoint = CGPointMake(y, x)
            if !isFrontCamera {
                p = pSwap(p)
                p = pRotate90(p, faceImg.height, faceImg.width)
            }
            
            guard self.isSizeValid else{
                clear()
                return nil
            }
            
            p = pScale(p, widthScaleBy, heightScaleBy)
            arrStrPoints .addObject(NSStringFromCGPoint(p))
            
        }
        
        self.totalFaceCounts+=1
        if self.totalFaceCounts == 100 {
            clear()
        }
        

        self.isFaceEyeValid(landmarkDic, imgHeight: faceImg.height, imgWidth: faceImg.width)
        self.isFaceMouthOpen(landmarkDic, imgHeight: faceImg.height, imgWidth: faceImg.width)
        self.isFaceHeadShake(landmarkDic, imgHeight: faceImg.height, imgWidth: faceImg.width)

        return arrStrPoints
    }
    
    
    func showFaceLandMarksAndFaceRectWithPersonsArray(arrPersons:NSArray){
        if (self.viewCanvas?.hidden == true) {
            self.viewCanvas?.hidden = false
        }
        
        self.viewCanvas?.arrPersons = arrPersons as [AnyObject]
        self.viewCanvas!.setNeedsDisplay()
    }
    
    
    func parseResult(paraList:NSArray) -> Void {
        
        do{
            let result = paraList[0] as! String
            let faceImg:IFlyFaceImage = paraList[1] as! IFlyFaceImage
            let resultData = result.dataUsingEncoding(NSUTF8StringEncoding)
            
            var faceDic:AnyObject? = try! NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions(rawValue: 0))
            guard (faceDic != nil) else {return}
            
            let faceRet:NSString? = faceDic!.objectForKey(KCIFlyFaceResultRet) as? NSString
            var faceArray:NSArray? = faceDic!.objectForKey(KCIFlyFaceResultFace) as? NSArray
            
            faceDic = nil
            
            var ret:Int32 = 0
            
            if faceRet != nil {
                ret = faceRet!.intValue
            }
            
            //NO face detected
            if (ret>0 || faceArray == nil || faceArray!.count<1) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.hideFace()
                })
                return
            }
            
            //face detected
            //let dataPtr = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(faceImg.data.bytes), faceImg.data.length)
            //let source:CGImageSourceRef = CGImageSourceCreateWithData(dataPtr,nil)!
            //let cgImage:CGImageRef = CGImageSourceCreateImageAtIndex(source,0,nil)!
            
            //把位数据转为CGImage
            let grayColorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceGray()!;
            let dataPtr = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(faceImg.data.bytes), faceImg.data.length)
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(dataPtr)
            let dataVoidPtr: UnsafeMutablePointer<Void> = unsafeBitCast(data, UnsafeMutablePointer<Void>.self)
            let context:CGContextRef = CGBitmapContextCreate(dataVoidPtr,Int(faceImg.width),Int(faceImg.height),8,Int(faceImg.width)*1,grayColorSpace,UInt32(CGImageAlphaInfo.None.rawValue))!
            let cgImage:CGImageRef = CGBitmapContextCreateImage(context)!
            let image = UIImage.init(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.LeftMirrored)
            //清空数据
            faceImg.data = nil
            //CGContextRelease(context)
            //CGColorSpaceRelease(grayColorSpace)
            self.testkkView.image = image

            
            let arrPersons:NSMutableArray = []
            
            for faceInArr in faceArray! {
                if (faceInArr.isKindOfClass(NSDictionary) ) {
                    var positionDic:AnyObject? = faceInArr.objectForKey(KCIFlyFaceResultPosition)
                    let rectString:AnyObject? = self.parseDetect(positionDic as! NSDictionary, faceImg:faceImg)
                    positionDic = nil
                    
                    var landmarkDic:AnyObject? = faceInArr.objectForKey(KCIFlyFaceResultLandmark)
                    //                    if landmarkDic == nil {
                    //                        return
                    //                    }
                    
                    var strPoints:NSArray? = self.parseAlign(landmarkDic as? NSDictionary, orignImage: faceImg)
                    landmarkDic = nil
                    
                    var dicPerson:AnyObject? = [:].mutableCopy()
                    if rectString != nil {
                        (dicPerson as! NSMutableDictionary).setValue(rectString, forKey: RECT_KEY)
                    }
                    
                    if strPoints?.count>0 {
                        (dicPerson as! NSMutableDictionary).setValue(strPoints, forKey: POINTS_KEY)
                    }else{
                        //                        return
                    }
                    
                    strPoints = nil
                    
                    (dicPerson as! NSMutableDictionary).setValue("", forKey: RECT_ORI)
                    arrPersons.addObject(dicPerson as! NSMutableDictionary)
                    
                    dicPerson = nil
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.showFaceLandMarksAndFaceRectWithPersonsArray(arrPersons)
                    })
                    
                }
            }
            
            faceArray = nil;
            
        }catch let exception as NSException{
            print("KKKFaceService:exception----\(exception.name)")
        }
        
        
        
    }
    //MARK: ----IFlyFaceRequestDelegate
    func onEvent(eventType: Int32, withBundle params: String!) {
        print("onEvent | params: \(params)")
    }
    
    func onData(data: NSData!) {
        print("onData | ")
        //result:{"ret":"11700","uid":"1192348359","sst":"reg","sid":"wfr010063d6@ch3d550b189926475400"}
        
        let result :String = String.init(data: data, encoding: NSUTF8StringEncoding)!
        print("result:\(result)")
        
        
        let jsonArr = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        
        if (jsonArr.count == 0) {
            return
        }
        
        // 获取动作类型
        let strSessionType = jsonArr[KCIFlyFaceResultSST]
        
        // 人脸注册
        if (strSessionType!.isEqualToString(KCIFlyFaceResultReg)) {
            // 人脸识别是否成功
            let rst = jsonArr[KCIFlyFaceResultRST]
            // 错误码
            let ret = jsonArr[KCIFlyFaceResultRet]
            
            // 如果返回错误码不等于0，则表示注册遇到错误，并打印错误码
            if (ret?.integerValue != 0) {
                detectStatus = .KKKFaceDetectStatusRegisterFail
                self.showStatus()
                
            } else {
                // 如果结果为success，则表示注册成功
                // 设置提示，并保存gid（人脸模型ID）
                if let _ = rst?.isEqualToString(KCIFlyFaceResultSuccess) {
                    
                    // 保存人脸模型ID
                    let gid = jsonArr[KCIFlyFaceResultGID]
                    print("人脸模型ID\(String(gid!))")
                    self.faceGID = gid as? String;
                    self.saveFaceGID()
                    detectStatus = .KKKFaceDetectStatusRegisterSuccess
                    self.showStatus()
                    
                } else {
                    detectStatus = .KKKFaceDetectStatusRegisterFail
                    self.showStatus()
                }
            }
        }
        
        // 人脸验证
        if (strSessionType!.isEqualToString(KCIFlyFaceResultVerify)) {
            // 人脸识别是否成功
            let rst = jsonArr[KCIFlyFaceResultRST]
            // 会话ID
            _ = jsonArr["sid"]
            // 错误码
            let ret = jsonArr[KCIFlyFaceResultRet]
            
            if ret?.integerValue != 0 {
                detectStatus = .KKKFaceDetectStatusRecognitionFail
                self.showStatus()
            } else {
                if let _ = rst?.isEqualToString(KCIFlyFaceResultSuccess) {
                    print("检测到人脸")
                } else {
                    print("未检测到人脸")
                }
                
                // 校验是否成功
                let verf = jsonArr[KCIFlyFaceResultVerf]
                // 校验相似度
                _ = jsonArr["score"]
                self.faceScore = String.init(format: "%.2f", (jsonArr["score"]?.floatValue)!)
                
                if let _ = verf?.boolValue {
                    detectStatus = .KKKFaceDetectStatusRecognitionSuccess
                    self.showStatus()
                    
                } else {
                    detectStatus = .KKKFaceDetectStatusRecognitionFail
                    self.showStatus()
                }
            }
        }
        
        print("记录数: \(jsonArr.count)")
        print(jsonArr)

        
        //            if result.isEmpty {
        //                self.resultStrings = self.resultStrings?.stringByAppendingString(result)
        //            }
    }
    
    func onCompleted(error: IFlySpeechError?) {
        if let er = error {
            print("onCompleted | error:\(er.errorDesc)")
            let errorInfo = "错误码：\(error!.errorCode)\n 错误描述：\(error!.errorDesc)"
            //                self.performSelectorOnMainThread(#selector(showResultInfo), withObject: errorInfo, waitUntilDone: false)
        }else {
            //                self.performSelectorOnMainThread(#selector(showResultInfo), withObject: "成功啦", waitUntilDone: false)
        }
    }
    
    func showResultInfo(resultInfo:String) {
        let alert = UIAlertView.init(title: "结果", message: resultInfo, delegate: self, cancelButtonTitle: "确定")
        alert.show()
    }
    
    
    
    
    
    //MARK: ----helper
    
    
    func showStatus()  {
        var prefix = "-------识别中-------\n"
        if self.isRegister {
            prefix = "-------注册中-------\n"
        }
        var info:String
        switch detectStatus! {
        case .KKKFaceDetectStatusWaiting:
            info = "请把脸部放入橙色框框中..."
        case .KKKFaceDetectStatusTooClose:
            info = "远..一..点,脸放在橙色框框中"
        case .KKKFaceDetectStatusTooFar:
            info = "近一点，脸放在橙色框框中"
        case .KKKFaceDetectStatusToAdjustFace:
            info = "调整ing..."
        case .KKKFaceDetectStatusToBlinkEye:
            info = "请眨眼"
        case .KKKFaceDetectStatusToOpenMouth:
            info = "请张开你的大嘴.."
        case .KKKFaceDetectStatusToShakeHead:
            info = "请摇摇你的脑袋.."
        case .KKKFaceDetectStatusToRequest:
            info = "不要动,1s后拍照..."
        case .KKKFaceDetectStatusRegisterFail:
            info = "注册失败"
        case .KKKFaceDetectStatusRegisterSuccess:
            info = "注册成功"
            addLeftBarAction()
        case .KKKFaceDetectStatusRecognitionFail:
            info = "识别失败"
            addLeftBarAction()
        case .KKKFaceDetectStatusRecognitionSuccess:
            info = "GID:\(self.faceGID):识别成功-\(self.faceScore)分"
            addLeftBarAction()
        default:
            info = "默认检测人脸ing..."
        }
        self.infoLabel.text = prefix + info
        
    }
    
    func toggleRegister()  {
        self.isRegister = true
    }
    
    func hideFace(){
        guard self.viewCanvas!.hidden else{
            self.viewCanvas?.hidden = true
            return
        }
    }
    
    func clear(){
        self.totalFaceCounts = 0
        
        self.eyeLeftYLast = 0
        self.eyeLeftCornerYLast = 0
        self.eyeRightCornerYLast = 0
        self.eyeLeftOpenedCounts = 0
        self.eyeLeftYLast = 0
        
        self.mouthOpenedCounts = 0
        self.mouthWidthLast = 0
        self.mouthHeightLast = 0
        
        self.noseX = 0
        self.noseXLeft = 0
        self.noseXRight = 0
        
        
        self.isSizeValid = false
        self.isEyeValid = false
        self.isMouthValid = false
        self.isShakingValide = false
        
        self.detectStatus = .KKKFaceDetectStatusWaiting
    }
    
    
    func loadConfigData() {
        self.faceGID =  NSUserDefaults.standardUserDefaults().valueForKey("faceGID") as! String!
        if self.faceGID != nil {
            self.isRegister = false
        }else{
            self.isRegister = true
        }
    }

    func saveFaceGID(){
        let userDefault = NSUserDefaults.standardUserDefaults()
        userDefault.setObject(self.faceGID, forKey: "faceGID")
        userDefault.synchronize()
    }
    
    func deleteFaceGID() {
        let userDefault = NSUserDefaults.standardUserDefaults()
        userDefault.removeObjectForKey("faceGID")
        userDefault.synchronize()
        self.isRegister = true
        self.navigationItem.rightBarButtonItem = nil
    }
    
    //MARK: ----Request: register or recognition
    
    func doFaceRequest()  {
        self.clear()
        
        

        self.resultStrings = nil;
        //if self.iFlySpFaceRequest == nil{
            self.iFlySpFaceRequest = IFlyFaceRequest.sharedInstance()
            self.iFlySpFaceRequest?.delegate = self
            self.iFlySpFaceRequest?.setParameter(kIFlyAPPID, forKey: IFlySpeechConstant.APPID())
            self.iFlySpFaceRequest?.setParameter(kIFlyAPPID, forKey: "auth_id")
            self.iFlySpFaceRequest?.setParameter("del", forKey: "property")
        //}
        
        if isRegister == true {
            self.iFlySpFaceRequest?.setParameter(IFlySpeechConstant.FACE_REG(), forKey: IFlySpeechConstant.FACE_SST())
            //  压缩图片大小
//            testkkView.image = UIImage.init(named: "111.jpg")
            
            let requestImg:UIImage = testkkView.image!
            UIGraphicsBeginImageContext(CGSize(width: (requestImg.size.width)/2.0, height: (requestImg.size.height)/2.0))
            requestImg.drawInRect(CGRectMake(0.0, 0.0, (requestImg.size.width)/2.0, (requestImg.size.height)/2.0))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            let imgData = UIImageJPEGRepresentation(newImage, 0.001)!

//            let imgData = testkkView.image!.compressedData()
//            let imgData:NSData = UIImageJPEGRepresentation(testkkView.image!,1.0)!
            
            let dateFormatter:NSDateFormatter = NSDateFormatter();
            dateFormatter.dateFormat = "yyyyMMddHHmmss";
            let dateString:String = dateFormatter.stringFromDate(NSDate())
            
            
            var paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, .UserDomainMask, true)
            let cachePath = paths[0]
            imgData.writeToFile(cachePath+"/"+dateString, atomically: true)

            print("reg image data length: \(imgData.length)")
            self.iFlySpFaceRequest?.sendRequest(imgData)
        }else{
            
            self.iFlySpFaceRequest?.setParameter(IFlySpeechConstant.FACE_VERIFY(), forKey: IFlySpeechConstant.FACE_SST())
            self.iFlySpFaceRequest?.setParameter(self.faceGID, forKey: IFlySpeechConstant.FACE_GID())
            self.iFlySpFaceRequest?.setParameter("2000", forKey: "wait_time")
            //  压缩图片大小

            
            
//            let imgData = testkkView.image!.compressedData()
            
            let requestImg:UIImage = testkkView.image!
            UIGraphicsBeginImageContext(CGSize(width: (requestImg.size.width)/2.0, height: (requestImg.size.height)/2.0))
            requestImg.drawInRect(CGRectMake(0.0, 0.0, (requestImg.size.width)/2.0, (requestImg.size.height)/2.0))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            let imgData = UIImageJPEGRepresentation(newImage, 0.001)!

            print("faceid:\(self.faceGID),verify image data length: \(imgData.length)")
            self.iFlySpFaceRequest?.sendRequest(imgData)
        }
        
    }

    
    
    
    func doCapturePhoto() -> Void {
        var videoConnection:AVCaptureConnection?
        
        for connection in (self.stillImageOutput?.connections)! {
            guard let inputPorts: [AVCaptureInputPort] = connection.inputPorts as? [AVCaptureInputPort] else {
                return
            }
            for port in inputPorts {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
        }

        
        self.stillImageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { buffer, error in
            
            guard let buffer = buffer, imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), image = UIImage(data: imageData) else {
//                completion(nil)
                return
            }
            
            self.testkkView.image = image
            if ((self.captureManager?.session.running) == true){
                self.previewLayer?.session.stopRunning()
            }
            self.doFaceRequest()
            
        })

    }
    
    //MARK: ----Parser
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
