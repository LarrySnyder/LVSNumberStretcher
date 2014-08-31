//
//  LVSNumberStretcher.h
//  LVSNumberStretcher
//
//  Created by Larry Snyder on 8/31/14.
//  Copyright (c) 2014 Larry Snyder. All rights reserved.
//

#import <UIKit/UIKit.h>

/* --- LVSNumberStretcher --- */

@interface LVSNumberStretcher : UITextField

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

#pragma mark - Behavior

/*
 Indicates whether changes in the value of the stretcher generate continuous
 update events. Defaults to YES
 */
@property (nonatomic, assign, getter = isContinuous) BOOL continuous;

@end


/* --- LVSStretchGestureRecognizer --- */

@interface LVSStretchGestureRecognizer : UIPanGestureRecognizer

/*
 Vertical distance from touch location to control. 
 + indicates touch is above control, - indicates touch is below control
 */
@property (nonatomic, assign) CGFloat touchDistance;

@end