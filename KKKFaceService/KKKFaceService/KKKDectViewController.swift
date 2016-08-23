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

class KKKDectViewController: UIViewController,IFlyFaceRequestDelegate,CaptureManagerDelegate {

    @IBOutlet weak var previewView: UIView!
    
    @IBOutlet weak var testkkView: UIImageView!
    
    var captureManager:CaptureManager?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var viewCanvas:CanvasView?
    var faceDetector:IFlyFaceDetector?
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.title = "检测人脸"
        
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
    
    func hideFace(){
        guard self.viewCanvas!.hidden else{
            self.viewCanvas?.hidden = true
            return
        }
    }
    
    func parseDetect(positionDic:NSDictionary,faceImg:IFlyFaceImage) -> NSString {
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
        
        rectFace = rScale(rectFace, widthScaleBy, heightScaleBy)
        return  NSStringFromCGRect(rectFace)
    }
    
    func parseAlign(landmarkDic:NSDictionary?,orignImage faceImg:IFlyFaceImage) -> NSMutableArray {
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
