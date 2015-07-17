//
//  ACLoupe.swift
//  LinearDraggerDemo
//
//  Created by SUN Ka Meng Isaac on 7/7/15.
//  Copyright (c) 2015 SUN Ka Meng Isaac. All rights reserved.
//

import UIKit
import Foundation

class ACLoupe : ACMagnifyingGlass {
    
    static let kACLoupeDefaultRadius: CGFloat = 64
    var loupeImageView: UIImageView?
    
    convenience init() {
        self.init(frame: CGRectMake(0, 0, ACLoupe.kACLoupeDefaultRadius*2.0, ACLoupe.kACLoupeDefaultRadius*2.0))
    }
    
    override init(frame defaultFrame: CGRect) {
        super.init(frame: defaultFrame)
        self.layer.borderWidth = 0
        
        switch UIDevice.currentDevice().systemVersion.compare("7.0.0", options: NSStringCompareOptions.NumericSearch) {
        case .OrderedSame, .OrderedDescending:
            loupeImageView = UIImageView(frame: CGRectOffset(CGRectInset(self.bounds, -3.0, -3.0), 0, 2.5))
            loupeImageView?.image = UIImage(named: "kb-loupe-hi_7")
            break
        default:
            loupeImageView = UIImageView(frame: CGRectOffset(CGRectInset(bounds, -5.0, -5.0), 0, 2.0))
            loupeImageView!.image = UIImage(named: "kb-loupe-hi_6")
            break
        }
        loupeImageView?.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}