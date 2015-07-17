//
//  ACMagnifyingView.swift
//  LinearDraggerDemo
//
//  Created by SUN Ka Meng Isaac on 8/7/15.
//  Copyright (c) 2015 SUN Ka Meng Isaac. All rights reserved.
//

import Foundation
import GoogleMaps
import UIKit

class ACMagnifyingView: UIView {
    static let kACMagnifyingViewDefaultShowDelay: CGFloat = 0.5
    
    var magnifyingGlass: ACMagnifyingGlass!
    var magnifyingGlassShowDelay: CGFloat?
    var touchTimer: NSTimer?
    var mapView: GMSMapView?
    var isViewShown = false
    
    override init(frame defaultFrame: CGRect) {
        super.init(frame: defaultFrame)
        magnifyingGlassShowDelay = ACMagnifyingView.kACMagnifyingViewDefaultShowDelay
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addMagnifyingGlassTimer(timer: NSTimer) {
        let value: NSValue = timer.userInfo! as! NSValue
        let point: CGPoint = value.CGPointValue()
        isViewShown = true
        addMagnifyingGlassAtPoint(point)
    }
    
    func addMagnifyingGlassAtPoint(point: CGPoint) {
        if (magnifyingGlass == nil) {
            magnifyingGlass = ACMagnifyingGlass()
            magnifyingGlass.viewToMagnify = self
            magnifyingGlass.touchPoint = point
            self.superview!.addSubview(magnifyingGlass)
            magnifyingGlass.setNeedsDisplay()
        }
    }
    
    func updateMagnifyingGlassAtPoint(point: CGPoint) {
        magnifyingGlass.touchPoint = point
        magnifyingGlass.setNeedsDisplay()
    }

    
    func removeMagnifyingGlass() {
        magnifyingGlass?.removeFromSuperview()
        isViewShown = false
    }
    
    
    // MARK: - Touch Events
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        var nsTouches = touches as NSSet
        if let touch = nsTouches.anyObject() as? UITouch {
            self.touchTimer = NSTimer(timeInterval: NSTimeInterval(magnifyingGlassShowDelay!), target: self, selector: "addMagnifyingGlassTimer:", userInfo: NSValue(CGPoint: touch.locationInView(self)), repeats: false)
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            updateMagnifyingGlassAtPoint(touch.locationInView(self))
        }
        else {
            println("touchesMoved: failed")
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        touchTimer?.invalidate()
        touchTimer = nil
        removeMagnifyingGlass()
    }
}