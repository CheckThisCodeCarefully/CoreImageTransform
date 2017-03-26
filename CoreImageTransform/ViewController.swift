//
//  ViewController.swift
//  CoreImageTransform
//
//  Created by Eduard Panasiuk on 3/12/17.
//  Copyright © 2017 Eduard Panasiuk. All rights reserved.
//

import UIKit
import CoreGraphics

class ViewController: UIViewController {

    private let calculationLayer = CALayer()
    private let calculationSubLayer = CALayer()
    
    private let kPerspectiveM34:CGFloat = 1 / -2500;

    private var image:CIImage!
    private var processedImage:CIImage!

    private var timer:CADisplayLink!
    private var renderQueue:DispatchQueue!

    private var imageSize:CGSize!
    
    @IBOutlet weak var oySlider: UISlider!
    @IBOutlet weak var oyLabel: UILabel!
    @IBOutlet weak var renderView: CIImageView!

    //MARK: actions
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if(sender == oySlider){
            processOY()
            return
        }
    }

    //MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        let resource = UIImage(named: "image")!.cgImage!
        renderQueue = DispatchQueue(label: "com.render.queue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        image = CIImage(cgImage:resource)
        processedImage = image
        timer = CADisplayLink(target: self, selector: #selector(render))
        timer.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
        imageSize = CGSize(width: resource.width, height: resource.height)
        updateSliderLabel()
        
        calculationLayer.addSublayer(calculationSubLayer)
    }

    //MARK: private
    private func processOY() {
        makeTransformForOY(degree: CGFloat(oySlider.value))
        updateSliderLabel()
    }

    private func updateSliderLabel() {
        oyLabel.text = "\(oySlider.value)"
    }

    private func makeTransformForOY(degree: CGFloat) {
        renderQueue.async { [weak self] in
            guard let s = self else {
                return
            }
            
            var transform = s.transfotm(oyAngle: degree)
            var anchorPoint = degree >= 0 ? CGPoint(x:0, y:0.5) : CGPoint(x:1, y:0.5)
            if(degree == 0){
                anchorPoint = CGPoint(x: 0.5, y: 0.5)
                transform = CATransform3DIdentity
            }
            var points = s.maketransformPoints(transform: transform, anchorPoint: anchorPoint)
            
            
            let perspectiveTransform = CIFilter(name: "CIPerspectiveTransform")!
            
            perspectiveTransform.setValue(CIVector(cgPoint:points[3]),
                                          forKey: "inputTopLeft")
            perspectiveTransform.setValue(CIVector(cgPoint:points[2]),
                                          forKey: "inputTopRight")
            perspectiveTransform.setValue(CIVector(cgPoint:points[1]),
                                          forKey: "inputBottomRight")
            perspectiveTransform.setValue(CIVector(cgPoint:points[0]),
                                          forKey: "inputBottomLeft")
            perspectiveTransform.setValue(s.image,
                                          forKey: kCIInputImageKey)
            let result = perspectiveTransform.outputImage!
            s.processedImage = result
        }
    }

    private func degreeToRadian(degree: CGFloat) -> CGFloat {
        let result = degree * .pi / 180
        return result
    }

    private func transfotm(oyAngle:CGFloat) -> CATransform3D {
        let radian = degreeToRadian(degree: oyAngle)
        var transform = CATransform3DIdentity
        transform.m34 = kPerspectiveM34;
        return CATransform3DRotate(transform, radian, 0, 1, 0)
    }

    @objc private func  render(){
        renderView.setRenderImage(image: processedImage)
    }
    
    private func aplyAnchorPoint(_ point:CGPoint) {
        if(__CGPointEqualToPoint(self.calculationSubLayer.anchorPoint, point)){
            return
        }
        
        calculationSubLayer.anchorPoint = point
    }
    
    //dirty solution with CALayer
    private func maketransformPoints(transform:CATransform3D, anchorPoint:CGPoint) -> [CGPoint] {
        var points:[CGPoint] = []
        
        calculationLayer.transform = CATransform3DIdentity
        calculationLayer.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        calculationSubLayer.transform = CATransform3DIdentity
        calculationSubLayer.frame = calculationLayer.bounds
        aplyAnchorPoint(anchorPoint)
        calculationSubLayer.transform = transform
        points = [
            calculationSubLayer.convert(CGPoint(x:0, y:0), to: calculationLayer),
            calculationSubLayer.convert(CGPoint(x:imageSize.width, y:0), to: calculationLayer),
            calculationSubLayer.convert(CGPoint(x:imageSize.width, y:imageSize.height), to: calculationLayer),
            calculationSubLayer.convert(CGPoint(x:0, y:imageSize.height), to: calculationLayer),
        ]
        
        return points
    }
    
}


