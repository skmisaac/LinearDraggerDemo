//
//  ACMagnifyingView.h
//  MagnifyingGlass
//
//  Created by Arnaud Coomans on 30/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACMagnifyingGlass;
@class GMSMapView;

@interface ACMagnifyingView : UIView

@property (nonatomic, retain) ACMagnifyingGlass *magnifyingGlass;
@property (nonatomic, assign) CGFloat magnifyingGlassShowDelay;
@property (nonatomic, retain) NSTimer *touchTimer;
@property (nonatomic, assign) GMSMapView *mapView;

- (void)addMagnifyingGlassAtPoint:(CGPoint)point;
- (void)addMagnifyingGlassTimer:(NSTimer*)timer;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)removeMagnifyingGlass;
- (void)updateMagnifyingGlassAtPoint:(CGPoint)point;

@end
