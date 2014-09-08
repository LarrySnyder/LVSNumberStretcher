//
//  LVSNumberStretcher.h
//  LVSNumberStretcher
//
//  Created by Larry Snyder on 8/31/14.
//  Copyright (c) 2014 Larry Snyder. All rights reserved.
//

#import <UIKit/UIKit.h>

/* --- LVSNumberStretcher --- */

@interface LVSNumberStretcher : UIControl <UITextFieldDelegate, UIGestureRecognizerDelegate>

#pragma mark - Text field

/*
 Pointer to the text field that is the main visible component of hte number stretcher
 */
@property (nonatomic, strong) UITextField *textField;

#pragma mark - Value

/*
 Contains the current value
 */
@property (nonatomic, assign) CGFloat value;

/* 
 Sets the value the stretcher should contain, with optional animation of the change 
 */
- (void)setValue:(CGFloat)value animated:(BOOL)animated;

#pragma mark - Value limits

/*
 Minimum value of the stretcher. Defaults to 0
 */
@property (nonatomic, assign) CGFloat minimumValue;

/*
 Maximum value of the stretcher. Defaults to 100
 */
@property (nonatomic, assign) CGFloat maximumValue;

/*
 Increment of the stretcher. Defaults to 1
 */
@property (nonatomic, assign) CGFloat increment;

#pragma mark - Appearance

/*
 Number of digits to display after decimal. Defaults to 1
 */
@property (nonatomic, assign) int numDigits;

/*
 Frame in which to draw circular part of stretcher. Set to CGRectZero to use
 smallest square that contains self.frame. Defaults to CGRectZero
 */
@property (nonatomic, assign) CGRect circleFrame;

/*
 Angular width (in radians) of stretcher, where it intersects circle around text field.
 Defaults to pi/4
 */
@property (nonatomic, assign) CGFloat stretcherWidth;

/*
 Line width for circular part of stretcher. Defaults to 1.0
 */
@property (nonatomic, assign) CGFloat circleLineWidth;

/*
 Line color for circular part of stretcher. Defaults to black
 */
@property (nonatomic, strong) UIColor *circleLineColor;

/*
 Fill color for circular part of stretcher. Defaults to white
 */
@property (nonatomic, strong) UIColor *circleFillColor;

/*
 Line width for pointer part of stretcher. Defaults to 1.0
 */
@property (nonatomic, assign) CGFloat stretcherLineWidth;

/*
 Line color for pointer part of stretcher. Defaults to black
 */
@property (nonatomic, strong) UIColor *stretcherLineColor;

/*
 Fill color for pointer part of stretcher. Defaults to black
 */
@property (nonatomic, strong) UIColor *stretcherFillColor;


#pragma mark - Behavior

/*
 Whether to stretch in response to pan (usePanGesture = YES) or long-press and movement
 (usePanGesture = NO). Defaults to YES
 */
@property (nonatomic, assign) BOOL usePanGesture;

/*
 Maximum distance -- if stretcher is stretched past this distance, 
 value will increment at maximumIncrementSpeed (measured in points).
 Defaults to 150
 */
@property (nonatomic, assign) CGFloat maximumDistance;

/*
 Minimum speed at which stretcher value changes (measured in # increments per second).
 Defaults to 1 */
@property (nonatomic, assign) CGFloat minimumIncrementSpeed;

/*
 Speed at which stretcher value changes when stretched past maximumDistance
 (measured in # increments per second). Defaults to 3
 */
@property (nonatomic, assign) CGFloat maximumIncrementSpeed;

/*
 Indicates whether changes in the value of the stretcher generate continuous
 update events. Defaults to YES
 */
@property (nonatomic, assign, getter = isContinuous) BOOL continuous;

@end
