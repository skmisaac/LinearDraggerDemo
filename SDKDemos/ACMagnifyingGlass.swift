//
//  ACMagnifyingGlass.swift
//  LinearDraggerDemo
//
//  Created by SUN Ka Meng Isaac on 7/7/15.
//  Copyright (c) 2015 SUN Ka Meng Isaac. All rights reserved.
//

import UIKit
import Foundation

class ACMagnifyingGlass : UIView {
    static let kACMagnifyingGlassDefaultRadius: CGFloat = 40;
    static let kACMagnifyingGlassDefaultOffset: CGFloat = -40;
    static let kACMagnifyingGlassDefaultScale:  CGFloat = 1.5;
    
    var viewToMagnify: UIView?
    var touchPoint: CGPoint?
    var touchPointOffset: CGPoint = CGPointMake(0, ACMagnifyingGlass.kACMagnifyingGlassDefaultOffset)
    var scale: CGFloat = ACMagnifyingGlass.kACMagnifyingGlassDefaultScale
    var scaleAtTouchPoint = true
    
    override var frame: CGRect {
        set(rect) {
            super.frame = rect
            layer.cornerRadius = rect.size.width / 2;
        }
        
        get {
            return super.frame
        }
    }
    
    convenience init() {
        let defaultFrame = CGRectMake(0, 0, ACMagnifyingGlass.kACMagnifyingGlassDefaultRadius*2, ACMagnifyingGlass.kACMagnifyingGlassDefaultRadius*2)
        self.init(frame: defaultFrame)
    }
    
    override init(frame defaultFrame: CGRect) {
        super.init(frame: defaultFrame)
        layer.borderColor = UIColor.lightGrayColor().CGColor
        layer.borderWidth = 3
        layer.cornerRadius = frame.size.width / 2
        layer.masksToBounds = true
        viewToMagnify = nil
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setTouchPoint(point: CGPoint) {
        touchPoint = point
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, frame.size.width/2, frame.size.height/2)
        CGContextScaleCTM(context, scale, scale)
        CGContextTranslateCTM(context, -(touchPoint!.x), -(touchPoint!.y) + (scaleAtTouchPoint ? 0 : bounds.size.height / 2))
        viewToMagnify?.layer.renderInContext(context)
    }
}