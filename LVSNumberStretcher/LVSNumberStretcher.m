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
//	LVSStretchGestureRecognizer *_stretchRecognizer;
	UIPanGestureRecognizer *_panRecognizer;
	UITextField *_textField;
	BOOL _incrementing;
//	int _currentIncrementDirection;		// 1 = increasing, 0 = not incrementing, -1 = decreasing
	CGFloat _currentIncrementSpeed;		// increments per second (+ = increasing, - = decreasing)
	BOOL _nextIncrementScheduled;		// has next increment been scheduled?
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		// Create text field
		_textField = [[UITextField alloc] initWithFrame:CGRectMake(self.bounds.size.width / 3, self.bounds.size.height /3, self.bounds.size.width / 3, self.bounds.size.height /3)];
		[self addSubview:_textField];
		
		// Default property values
		self.minimumValue = -DBL_MAX; // 0.0;
		self.maximumValue = DBL_MAX; // 100.0;
		self.value = 0.0;
		self.increment = 1;
		self.numDigits = 1;
		self.maximumDistance = 150.0;
		self.minimumIncrementSpeed = 1.0;
		self.maximumIncrementSpeed = 10.0;
		self.continuous = YES;
		
		// Initial increment settings
		_incrementing = NO;
		_currentIncrementSpeed = 0.0;
		_nextIncrementScheduled = NO;
		
		// Initial appearance
		self.backgroundColor = [UIColor lightGrayColor];
		_textField.textColor = [UIColor blueColor];
		_textField.backgroundColor = [UIColor whiteColor];
																	   
		// Enable
		_textField.enabled = YES;
		
		// Gesture recognizer
		_panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleStretch:)];
		_panRecognizer.minimumNumberOfTouches = 1;
		_panRecognizer.maximumNumberOfTouches = 1;
		[self addGestureRecognizer:_panRecognizer];
//		_stretchRecognizer = [[LVSStretchGestureRecognizer alloc] initWithTarget:self action:@selector(handleStretch:)];
//		[self addGestureRecognizer:_stretchRecognizer];
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
		_textField.text = [NSString stringWithFormat:formatStr, _value];
	}
}

#pragma mark - Property gets/sets

- (void)setValue:(CGFloat)value
{
	// Chain with setValue:animated:
	[self setValue:value animated:NO];
}

#pragma mark - Stretching

- (void)handleStretch:(LVSStretchGestureRecognizer *)gesture
{
	if ((gesture.state == UIGestureRecognizerStateBegan) ||
		(gesture.state == UIGestureRecognizerStateChanged))
	{
		CGPoint touchPoint = [gesture locationInView:self];
		CGFloat touchDistance; // +/-
		
		// TODO: allow user to specify "up" direction and make everything relative to that
		
		// Calculate distance to nearest (top/bottom) edge
		if (touchPoint.y < CGRectGetMinY(self.bounds))
			touchDistance = CGRectGetMinY(self.bounds) - touchPoint.y;
		else if (touchPoint.y > CGRectGetMaxY(self.bounds))
			touchDistance = CGRectGetMaxY(self.bounds) - touchPoint.y;
		else
			touchDistance = 0.0;

		// Calculate increment speed
		_currentIncrementSpeed = self.maximumIncrementSpeed * touchDistance / self.maximumDistance;
		// There must be a more compact way to do this!!
		if (_currentIncrementSpeed > self.maximumIncrementSpeed)
			_currentIncrementSpeed = self.maximumIncrementSpeed;
		else if (_currentIncrementSpeed < -self.maximumIncrementSpeed)
			_currentIncrementSpeed = -self.maximumIncrementSpeed;
		else if (fabs(_currentIncrementSpeed) < self.minimumIncrementSpeed)
		{
			if (_currentIncrementSpeed > 0)
				_currentIncrementSpeed = self.minimumIncrementSpeed;
			else
				_currentIncrementSpeed = -self.minimumIncrementSpeed;
		}
		
		// Schedule next increment and set incrementing flag
		if (fabs(_currentIncrementSpeed) > 0.001)
		{
			if (!_nextIncrementScheduled)
			{
				[self performSelector:@selector(incrementValue)
						   withObject:nil
						   afterDelay:(1.0 / fabs(_currentIncrementSpeed))];
				_nextIncrementScheduled = YES;
			}
			_incrementing = YES;
		}
		else
		{
			_incrementing = NO;
			_nextIncrementScheduled = NO;
		}
	}
	else if ((gesture.state == UIGestureRecognizerStateEnded) ||
			 (gesture.state = UIGestureRecognizerStateCancelled) ||
			 (gesture.state == UIGestureRecognizerStateFailed))
	{
		// Gesture ended -- turn off incrementing
		_incrementing = NO;
		_nextIncrementScheduled = NO;
	}
}

- (void)incrementValue
{
	// Make sure we are still incrementing
	if (_incrementing)
	{
		// Increment value
		if (_currentIncrementSpeed > 0)
			self.value += self.increment;
		else
			self.value -= self.increment;
		
		// Schedule next increment
		[self performSelector:@selector(incrementValue)
				   withObject:nil
				   afterDelay:(1.0 / fabs(_currentIncrementSpeed))];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return NO;
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