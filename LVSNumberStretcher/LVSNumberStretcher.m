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
	UITapGestureRecognizer *_doubleTapRecognizer;
	UITextField *_textField;
	BOOL _incrementing;
	CGFloat _currentIncrementSpeed;		// increments per second (+ = increasing, - = decreasing)
	BOOL _nextIncrementScheduled;		// has next increment been scheduled?
	BOOL _editing;
	UIView *_circularFrame;
	CGRect _originalFrame;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		// Create text field
		_textField = [[UITextField alloc] initWithFrame:CGRectInset(self.frame, 5, 5)];
		[self addSubview:_textField];
		
		// Set up text field
		_textField.keyboardType = UIKeyboardTypeDecimalPad;
		_textField.enablesReturnKeyAutomatically = YES;
		_textField.textAlignment = NSTextAlignmentCenter;
		_textField.delegate = self;
		
		// Custom toolbar for keyboard (see http://stackoverflow.com/a/11382326/3453768)
		UIToolbar *numberToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
		numberToolbar.items = [NSArray arrayWithObjects:
//							   [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelNumberPad)],
							   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
							   [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
							   nil];
		_textField.inputAccessoryView = numberToolbar;
		
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
		
		// Initial editing settings
		_editing = NO;
		
		// Appearance
		self.backgroundColor = [UIColor lightGrayColor];
		_textField.textColor = [UIColor blueColor];
		_textField.backgroundColor = [UIColor whiteColor];
		_originalFrame = self.frame;
								
		// Pan gesture recognizer
		_panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleStretch:)];
		_panRecognizer.minimumNumberOfTouches = 1;
		_panRecognizer.maximumNumberOfTouches = 1;
		[self addGestureRecognizer:_panRecognizer];
		
		// Double-tap recognizer
		// basically uses the method here: http://stackoverflow.com/questions/20420784/double-tap-uitextview
		_doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
		_doubleTapRecognizer.numberOfTapsRequired = 2;
		_doubleTapRecognizer.numberOfTouchesRequired = 1;
		_doubleTapRecognizer.delaysTouchesBegan = YES;
		_doubleTapRecognizer.delegate = self;
		[self addGestureRecognizer:_doubleTapRecognizer];
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

- (void)handleStretch:(UIPanGestureRecognizer *)gesture
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
		
		// Update frames
		[self updateFramesForTouchPoint:touchPoint];
	}
	else if ((gesture.state == UIGestureRecognizerStateEnded) ||
			 (gesture.state = UIGestureRecognizerStateCancelled) ||
			 (gesture.state == UIGestureRecognizerStateFailed))
	{
		// Gesture ended -- turn off incrementing
		_incrementing = NO;
		_nextIncrementScheduled = NO;
		
		// Reset frame
		[self updateFramesForTouchPoint:_originalFrame.origin];
	}
	
/*	if (gesture.state == UIGestureRecognizerStateBegan)
		[self animateCircularFrame];*/
	
	// Redraw if gesture began or ended
	if ((gesture.state == UIGestureRecognizerStateBegan) ||
		(gesture.state == UIGestureRecognizerStateEnded) ||
		(gesture.state == UIGestureRecognizerStateCancelled) ||
		(gesture.state == UIGestureRecognizerStateFailed))
		[self setNeedsDisplay];
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

#pragma mark - Drawing and Animation

/* Updates frames of self and _textField in response to stretch to touchPoint.
	Set touchPoint to any point in _originalFrame to restore to original frames. */
- (void)updateFramesForTouchPoint:(CGPoint)touchPoint;
{
	// Remember original frame for _textField, in superview's coordinates
	CGRect textFrame = [self.superview convertRect:_textField.frame fromView:self];
	
	// self frame
	CGRect pointRect = CGRectMake(touchPoint.x, touchPoint.y, 0.0, 0.0);
	self.frame = CGRectUnion(pointRect, _originalFrame);
	
	// _textField frame
	_textField.frame = [self convertRect:textFrame fromView:self.superview];
}

- (void)drawRect:(CGRect)rect
{
	// Only draw circular frame if incrementing
	if (_incrementing)
	{
		// Get CGContextRef
		CGContextRef context = UIGraphicsGetCurrentContext();
		UIGraphicsPushContext(context);
		
		// Set drawing properties
		CGFloat lineWidth = 2.0;
		CGContextSetLineWidth(context, lineWidth);
		[[UIColor blackColor] setStroke];
		
		// Get slightly smaller rect to avoid circle being squished at edges
		CGRect slightlySmallerRect = CGRectInset(rect, lineWidth/2.0, lineWidth/2.0);
		
		// Draw circle
		CGContextAddEllipseInRect(context, slightlySmallerRect);
		CGContextDrawPath(context, kCGPathStroke);
		
		UIGraphicsPopContext();
	}
}

- (void)animateCircularFrame
{
/*	// Create circular frame and add as subview to self
	_circularFrame = [[UIView alloc] initWithFrame:CGRectZero];
	[self addSubview:_circularFrame];
	
	// Set initial animation state
	_circularFrame.frame = CGRectInset(self.bounds, self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
	_circularFrame.alpha = 0.0;
	
	// Animate appearance*/
	self.alpha = 0.0;
	[UIView animateWithDuration:1.0
						  delay:0.0
						options:0
					 animations:^{
						 self.alpha = 1.0;
					 }
					 completion:nil];
	
	
}

#pragma mark - Text field editing

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture
{
	_editing = YES;
	[_textField becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
	return _editing;
}

/*- (void)cancelNumberPad
{
	_editing = NO;
	[_textField resignFirstResponder];
}*/

- (void)doneWithNumberPad
{
	_editing = NO;
	[_textField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return _editing;
}

/*- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	[_textField selectAll:self];
}*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	_editing = NO;
	[textField resignFirstResponder];
	
	return YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

@end

