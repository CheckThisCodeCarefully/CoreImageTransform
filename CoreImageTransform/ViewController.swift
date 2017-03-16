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
            
            let transform = s.transfotm(oyAngle: degree)
            var points = s.makeTransformedImagePoints(transform: transform)
            
            if(degree > 0){
                points[0].x = s.imageSize.width - points[1].x
                points[1].x = s.imageSize.width
                points[3].x = s.imageSize.width - points[2].x
                points[2].x = s.imageSize.width
            }
            
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
        let result = degree * CGFloat(M_PI) / 180
        return result
    }

    private func transfotm(oyAngle:CGFloat) -> CATransform3D {
        let radian = degreeToRadian(degree: oyAngle)
            var transform = CATransform3DIdentity;
        transform.m34 = kPerspectiveM34;
        return CATransform3DRotate(transform, radian, 0, 1, 0)
    }

    @objc private func  render(){
        renderView.setRenderImage(image: processedImage)
    }
    
    private func convertPoint(p:CGPoint, transform:CATransform3D) -> CGPoint {
        let m1:[CGFloat] = [p.x, p.y, 0, 1]
        var m2:[[CGFloat]]  = Array();
        m2.append([transform.m11, transform.m12, transform.m13, transform.m14])
        m2.append([transform.m21, transform.m22, transform.m23, transform.m24])
        m2.append([transform.m31, transform.m32, transform.m33, transform.m34])
        m2.append([transform.m41, transform.m42, transform.m43, transform.m44])
        
        var result:[CGFloat] = Array()
        for i in 0...2 {
            var k:CGFloat = 0
            for j in 0...3 {
                k = k + m1[j] * (m2[j])[i]
            }
            result.append(k)
        }
        
        return CGPoint(x: result[0], y: result[1])
    }
    
    private func makeTransformedImagePoints(transform:CATransform3D) -> [CGPoint] {
        return [
            convertPoint(p: CGPoint(x:CGFloat(FLT_EPSILON), y:CGFloat(FLT_EPSILON)), transform: transform),
            convertPoint(p: CGPoint(x:imageSize.width, y:CGFloat(FLT_EPSILON)), transform: transform),
            convertPoint(p: CGPoint(x:imageSize.width, y:imageSize.height), transform: transform),
            convertPoint(p: CGPoint(x:CGFloat(FLT_EPSILON), y:imageSize.height), transform: transform),
        ]
    }
    
}


