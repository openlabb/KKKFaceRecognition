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
    
    var faceGID:String?
    var faceScore:String?
    var iFlySpFaceRequest: IFlyFaceRequest?
    
    var detector:KKKDetector
    //MARK: ----Life cycle
    private var statusContext = "statusContext"
    
    required init?(coder aDecoder: NSCoder) {
        self.isRegister = true
        self.detector = KKKDetector()
        super.init(coder: aDecoder)
        
        self.detector.addObserver(self, forKeyPath: "statusData", options: NSKeyValueObservingOptions.New, context: &statusContext)
        
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
    
    
    //MARK: ----UI

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
        self.previewLayer?.session.startRunning()
        self.detector.empty()
    }
    
    func addRightBarAction() -> Void {
        let item = UIBarButtonItem(title: "注册", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(deleteFaceGID))
        self.navigationItem.rightBarButtonItem = item
    }
    
    
    //MARK: ----KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &statusContext {
            if keyPath == "statusData" {
                self.showStatus()
            }
        }else{
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            self.captureManager?.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            
        }
        
    }
    
    
    deinit {
        self.detector.removeObserver(self, forKeyPath: "statusData", context: &statusContext)
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
        
        let cx:CGFloat = (left + right)/2
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
        
        let isFaceOK:Bool = self.detector.checkFaceValid(left, right: right, top: top, bottom: bottom)
        
        if isFaceOK {
            if self.detector.status == .KKKFaceDetectStatusToRequest{
                if ((self.captureManager?.session.running) == true){
                    self.previewLayer?.session.stopRunning()
                }
                //                    self.performSelector(#selector(doCapturePhoto), withObject: nil, afterDelay: 1)
                self.performSelector(#selector(doFaceRequest), withObject: nil, afterDelay: 0.1
                )
            }
            
        }else{
            //            return nil
        }
        
        
        //        print(" ✅ 1.检测到合格Size的人脸 -----\n")
        
        
        rectFace = rScale(rectFace, widthScaleBy, heightScaleBy)
        return  NSStringFromCGRect(rectFace)
    }
    
    func parseAlign(landmarkDic:NSDictionary?,orignImage faceImg:IFlyFaceImage) -> NSMutableArray? {
        if landmarkDic == nil || self.detector.status.rawValue < 4 {
            return[]
        }
        
        self.detector.checkStatus(landmarkDic!, imgHeight: faceImg.height, imgWidth: faceImg.width)
        
        
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
        //        do{
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
        
        //        }catch let exception as NSException{
        //            print("KKKFaceService:exception----\(exception.name)")
        //        }
        
        
        
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
                self.detector.status = .KKKFaceDetectStatusRegisterFail
                
            } else {
                // 如果结果为success，则表示注册成功
                // 设置提示，并保存gid（人脸模型ID）
                if let _ = rst?.isEqualToString(KCIFlyFaceResultSuccess) {
                    
                    // 保存人脸模型ID
                    let gid = jsonArr[KCIFlyFaceResultGID]
                    print("人脸模型ID\(String(gid!))")
                    self.faceGID = gid as? String;
                    self.saveFaceGID()
                    self.detector.status = .KKKFaceDetectStatusRegisterSuccess
                    
                } else {
                    self.detector.status = .KKKFaceDetectStatusRegisterFail
                }
                
            }
        }
        
        // 人脸验证
        if (strSessionType!.isEqualToString(KCIFlyFaceResultVerify)) {
            let rst = jsonArr[KCIFlyFaceResultRST]
            _ = jsonArr["sid"]
            let ret = jsonArr[KCIFlyFaceResultRet]
            if ret?.integerValue != 0 {
                self.detector.status = .KKKFaceDetectStatusRecognitionFail
            } else {
                if let _ = rst?.isEqualToString(KCIFlyFaceResultSuccess) {
                    print("检测到人脸")
                } else {
                    print("未检测到人脸")
                }
                
                let verf = jsonArr[KCIFlyFaceResultVerf]
                _ = jsonArr["score"]
                self.faceScore = String.init(format: "%.2f", (jsonArr["score"]?.floatValue)!)
                
                if let _ = verf?.boolValue {
                    self.detector.status = .KKKFaceDetectStatusRecognitionSuccess
                    
                } else {
                    self.detector.status = .KKKFaceDetectStatusRecognitionFail
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
            //            let errorInfo = "错误码：\(error!.errorCode)\n 错误描述：\(error!.errorDesc)"
            //                self.performSelectorOnMainThread(#selector(showResultInfo), withObject: errorInfo, waitUntilDone: false)
        }else {
            //                self.performSelectorOnMainThread(#selector(showResultInfo), withObject: "成功啦", waitUntilDone: false)
        }
    }
    
    func showResultInfo(resultInfo:String) {
        //        let alert = UIAlertView.init(title: "结果", message: resultInfo, delegate: self, cancelButtonTitle: "确定")
        //        alert.show()
    }
    
    //MARK: ----Request: register or recognition
    func doFaceRequest()  {
        
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
        
        self.detector.empty()
        
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
    
    
    //MARK: ----Helper
    func toggleRegister()  {
        self.isRegister = true
    }
    
    func hideFace(){
        guard self.viewCanvas!.hidden else{
            self.viewCanvas?.hidden = true
            return
        }
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
    
    func showStatus()  {
        var prefix = "-------识别中-------\n"
        if self.isRegister {
            prefix = "-------注册中-------\n"
        }
        var info:String
        switch self.detector.status {
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
            info = "不要动,1s后识别..."
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

    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
