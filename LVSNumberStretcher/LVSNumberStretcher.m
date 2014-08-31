//
//  LVSNumberStretcher.m
//  LVSNumberStretcher
//
//  Created by Larry Snyder on 8/31/14.
//  Copyright (c) 2014 Larry Snyder. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>

#import "LVSNumberStretcher.h"

/* --- LVSNumberStretcher --- */

@implementation LVSNumberStretcher
{
	LVSStretchGestureRecognizer *_stretchRecognizer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		// Default property values
		self.value = 0.0;
		self.minimumValue = 0.0;
		self.maximumValue = 100.0;
		self.increment = 1;
		self.numDigits = 1;
		self.continuous = YES;

		// Initial appearance
		self.backgroundColor = [UIColor lightGrayColor];
		self.textColor = [UIColor blueColor];
		
		// Enable
		self.enabled = YES;
		
		// Gesture recognizer
		_stretchRecognizer = [[LVSStretchGestureRecognizer alloc] initWithTarget:self action:@selector(handleStretch:)];
		[self addGestureRecognizer:_stretchRecognizer];
	}
    return self;
}

#pragma mark - API methods

- (void)setValue:(CGFloat)value animated:(BOOL)animated
{
  //  if (value != _value)
	{
		// Save value to backing ivar, ensuring bounds are respected
		_value = MIN(self.maximumValue, MAX(self.minimumValue, value));
		
		// Update text
		NSString *formatStr = [NSString stringWithFormat:@"%%.%df", self.numDigits];
		self.text = [NSString stringWithFormat:formatStr, _value];
	}
}

#pragma mark - Property overrides

- (void)setValue:(CGFloat)value
{
	// Chain with setValue:animated:
	[self setValue:value animated:NO];
}

#pragma mark - Gesture handling

- (void)handleStretch:(LVSStretchGestureRecognizer *)gesture
{
	// TEMP:
	self.value = gesture.touchDistance;
}

@end


/* --- LVSStretchGestureRecognizer --- */

@implementation LVSStretchGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.maximumNumberOfTouches = 1;
        self.minimumNumberOfTouches = 1;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	[self updateTouchDistanceWithTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	[self updateTouchDistanceWithTouches:touches];
}

- (void)updateTouchDistanceWithTouches:(NSSet *)touches
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.view];
	
	// TODO: allow user to specify "up" direction and make everything relative to that
	
	// Calculate distance to nearest (top/bottom) edge
	if (touchPoint.y < CGRectGetMinY(self.view.bounds))
		self.touchDistance = touchPoint.y - CGRectGetMinY(self.view.bounds);
	else if (touchPoint.y > CGRectGetMaxY(self.view.bounds))
		self.touchDistance = touchPoint.y - CGRectGetMaxY(self.view.bounds);
	else
		self.touchDistance = 0.0;
}

@end