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

public enum KKKFaceDetectStatus:Int {
    case KKKFaceDetectStatusWaiting
    case KKKFaceDetectStatusTooFar
    case KKKFaceDetectStatusTooClose
    case KKKFaceDetectStatusToAdjustFace
    case KKKFaceDetectStatusToOpenMouth
    case KKKFaceDetectStatusToShakeHead
    case KKKFaceDetectStatusToRequest
    case KKKFaceDetectStatusNone}

class KKKDectViewController: UIViewController,IFlyFaceRequestDelegate,CaptureManagerDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var testkkView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var isRegister:Bool
    
    var captureManager:CaptureManager?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var viewCanvas:CanvasView?
    var faceDetector:IFlyFaceDetector?
    
    var mouthWidthLast:Int?
    var mouthHeightLast:Int?
    var mouthOpenedCounts:Int?
    
    var mouthYTop:Int?
    var mouthYBottom:Int?
    var mouthXLeft:Int?
    var mouthXRight:Int?
    
    var noseX:Int?
    var noseXLeft:Int?
    var noseXRight:Int?
    
    var isSizeValid:Bool?
    var isMouthValid:Bool?
    var isShakingValide:Bool?
    var resultStrings:String?
    var faceGID:String?
    var iFlySpFaceRequest: IFlyFaceRequest?
    
    
    var detectStatus:KKKFaceDetectStatus?{
        didSet{
            showStatus()
        }
    }
    
    //MARK: ----Life cycle
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.isRegister = true
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
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
    
    func configSubViews() -> Void {
        self.addPrewLayer()
        self.addCanvas()
        self.captureManager?.setup()
        self.captureManager?.addObserver()
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
        
        print(" ✅ 检测到人脸 -----\(strResult)\n")
        
        
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
        }else if (xDelta > xDeltaMax || yDelta < yDeltaMax){
            detectStatus = .KKKFaceDetectStatusTooClose
        }else{
            self.isSizeValid = true
            if isMouthValid == false {
                if (left < 100 || top < 100 || right > 460 || bottom > 400) {
                    detectStatus =  .KKKFaceDetectStatusToAdjustFace
                }else{
                    ret = true
                }
            }
        }
        
        //        showStatus()
        guard ret else{
            self.clear()
            return false
        }
        
        return true
    }
    
    func checkFaceMouthOpen(key:String,p:CGPoint) -> Void {
        if key == "mouth_upper_lip_top" {
            mouthYTop = Int(p.y)
        }else if key == "mouth_lower_lip_bottom"{
            mouthYBottom = Int(p.y)
        }else if key == "mouth_left_corner"{
            mouthXLeft = Int(p.x)
        }else if key == "mouth_right_corner"{
            mouthXRight = Int(p.x)
        }
        if mouthXLeft>0 && mouthXRight>0 && mouthYTop>0 && mouthYBottom>0 && isMouthValid==false {
            mouthOpenedCounts! += 1
            if mouthOpenedCounts==1 || mouthOpenedCounts==300 || mouthOpenedCounts==600 || mouthOpenedCounts==900 {
                mouthWidthLast =  abs(mouthXRight! - mouthXLeft!)
                mouthHeightLast =  abs(mouthYBottom! - mouthYTop!)
            }
        }else if(mouthOpenedCounts > 1200){
            clear()
            self.detectStatus = .KKKFaceDetectStatusWaiting
            //            self.showStatus()
        }
        
        
        let mouthWidth:Int = abs(mouthXRight! - mouthXLeft!)
        let mouthHeight:Int = abs(mouthYBottom! - mouthYTop!)
        print("----张嘴前:\(mouthWidthLast),\(mouthHeightLast)")
        print("----张嘴后:\(mouthWidth),\(mouthHeight)")
        if mouthWidthLast>0 && mouthWidth>0 {
            if (mouthHeight - mouthHeightLast! >= 20 && mouthWidthLast! - mouthWidth >= 15) {
                isMouthValid = true
                detectStatus = .KKKFaceDetectStatusToShakeHead
            }
        }
        
    }
    
    func checkFaceHeadShake(key:String,p:CGPoint) -> Void {
        if key == "mouth_middle" && isMouthValid == true {
            if noseXRight == 0 {
                noseXRight = Int(p.x)
                noseXLeft = Int(p.x)
            }else if(Int(p.x) > noseXRight){
                noseXRight = Int(p.x)
            }else if(Int(p.x) < noseXLeft){
                noseXLeft = Int(p.x)
            }
            
            if  noseXRight! - noseXLeft! > 60 {
                isShakingValide = true
                clear()
                detectStatus = .KKKFaceDetectStatusToRequest
                
            }
        }
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
            
            let isFaceInValidLocation:Bool = self.isSizeValid!
            guard isFaceInValidLocation else{
                clear()
                return nil
            }
            
            self.checkFaceMouthOpen(key as! String, p: p)
            self.checkFaceHeadShake(key as! String, p: p)
            
            p = pScale(p, widthScaleBy, heightScaleBy)
            arrStrPoints .addObject(NSStringFromCGPoint(p))
            
        }
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
        let result :String = String.init(data: data, encoding: NSUTF8StringEncoding)!
        print("result:\(result)")
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
    
    
    //MARK: ----Request: register or recognition
    
    func doFaceRequest()  {
        self.resultStrings = nil;
        if self.iFlySpFaceRequest == nil {
            self.iFlySpFaceRequest=IFlyFaceRequest.sharedInstance()
            self.iFlySpFaceRequest?.delegate = self
            self.iFlySpFaceRequest?.setParameter("57899eda", forKey: IFlySpeechConstant.APPID())
            self.iFlySpFaceRequest?.setParameter("57899eda", forKey: "auth_id")
            self.iFlySpFaceRequest?.setParameter("del", forKey: "property")
        }
        
        if isRegister == true {
            self.iFlySpFaceRequest?.setParameter(IFlySpeechConstant.FACE_REG(), forKey: IFlySpeechConstant.FACE_SST())
            //  压缩图片大小
            let imgData = testkkView.image!.compressedData()
            print("reg image data length: \(imgData.length)")
            self.iFlySpFaceRequest?.sendRequest(imgData)
        }else{
            
            self.iFlySpFaceRequest?.setParameter(IFlySpeechConstant.FACE_VERIFY(), forKey: IFlySpeechConstant.FACE_SST())
            //            self.iFlySpFaceRequest?.setParameter(
            //                "e7c9663d3331a6f8ed211cb5417067cd", forKey: IFlySpeechConstant.FACE_GID())
            self.iFlySpFaceRequest?.setParameter(faceGID, forKey: IFlySpeechConstant.FACE_GID())
            self.iFlySpFaceRequest?.setParameter("2000", forKey: "wait_time")
            //  压缩图片大小
            let imgData = testkkView.image!.compressedData()
            print("verify image data length: \(imgData.length)")
            self.iFlySpFaceRequest?.sendRequest(imgData)
        }
        
    }
    
    
    
    //MARK: ----helper
    
    
    func showStatus()  {
        var info:String
        switch detectStatus! {
        case .KKKFaceDetectStatusWaiting:
            info = "检测人脸ing..."
        case .KKKFaceDetectStatusTooClose:
            info = "太近了"
        case .KKKFaceDetectStatusTooFar:
            info = "太...远...了"
        case .KKKFaceDetectStatusToAdjustFace:
            info = "调整ing..."
        case .KKKFaceDetectStatusToOpenMouth:
            info = "请张开你的大嘴三次.."
        case .KKKFaceDetectStatusToShakeHead:
            info = "请摇摇你的脑袋，三次.."
        case .KKKFaceDetectStatusToRequest:
            info = "正在识别..."
        default:
            info = "检测人脸ing..."
        }
        self.infoLabel.text = info
        
        if detectStatus == .KKKFaceDetectStatusToRequest {
            doFaceRequest()
        }
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
        self.mouthWidthLast = 0
        self.mouthHeightLast = 0
        self.noseX = 0
        self.noseXLeft = 0
        self.noseXRight = 0
        
        self.isSizeValid = false
        self.isMouthValid = false
        self.isShakingValide = false
        self.detectStatus = .KKKFaceDetectStatusWaiting
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
