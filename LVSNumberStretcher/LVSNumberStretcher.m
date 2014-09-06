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
//	UITextField *_textField;
	BOOL _incrementing;
	CGFloat _currentIncrementSpeed;		// increments per second (+ = increasing, - = decreasing)
	BOOL _nextIncrementScheduled;		// has next increment been scheduled?
	BOOL _editing;
	UIView *_circularFrame;
	CGRect _originalFrame;				// original frame of control, in superview's coordinates
	CGPoint _touchPoint;				// point currently being touched during stretch, in superview's coordinates
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		// Create text field
		_textField = [[UITextField alloc] initWithFrame:CGRectInset(self.bounds, 5, 5)];
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
		self.stretcherWidth = M_PI / 4.0;
		self.lineWidth = 1.0;
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
		self.backgroundColor = [UIColor clearColor];
		_textField.textColor = [UIColor blueColor];
		_textField.backgroundColor = [UIColor clearColor];
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
		// Get touch point in superview's coordinates
		_touchPoint = [gesture locationInView:self.superview];
		
		// TODO: allow user to specify "up" direction and make everything relative to that
		
		// Calculate distance to nearest (top/bottom) edge of original frame and increment speed
		CGFloat touchDistance; // +/-
		if (_touchPoint.y < CGRectGetMinY(_originalFrame))
		{
			// Touch is above frame: touchDistance and _currentIncrementSpeed will be >0
			touchDistance = CGRectGetMinY(_originalFrame) - _touchPoint.y;
			_currentIncrementSpeed = self.maximumIncrementSpeed * touchDistance / self.maximumDistance;
			_currentIncrementSpeed = MIN(self.maximumIncrementSpeed, MAX(_currentIncrementSpeed, self.minimumIncrementSpeed));
		}
		else if (_touchPoint.y > CGRectGetMaxY(_originalFrame))
		{
			// Touch is below frame: touchDistance and _currentIncrementSpeed will be <0
			touchDistance = CGRectGetMaxY(_originalFrame) - _touchPoint.y;
			_currentIncrementSpeed = self.maximumIncrementSpeed * touchDistance / self.maximumDistance;
			_currentIncrementSpeed = MAX(-self.maximumIncrementSpeed, MIN(_currentIncrementSpeed, -self.minimumIncrementSpeed));
		}
		else
		{
			// Touch is inside frame: touchDistance and _currentIncrementSpeed will be =0
			touchDistance = 0.0;
			_currentIncrementSpeed = 0.0;
		}
		
		// Set _incrementing (even if touch is within frame)
		_incrementing = YES;

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
		}
		else
			_nextIncrementScheduled = NO;
		
		// Update frames
		[self updateFramesForTouchPoint:_touchPoint];
		[self setNeedsDisplay];
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
	touchPoint must be in superview's coordinates.
	Set touchPoint to any point in _originalFrame to restore to original frames. */
- (void)updateFramesForTouchPoint:(CGPoint)touchPoint;
{
	// Remember original frame for _textField, in superview's coordinates
	CGRect textFrame = [self.superview convertRect:_textField.frame fromView:self];
	
	// self frame
	CGRect pointRect = CGRectMake(CGRectGetMidX(_originalFrame), touchPoint.y, 0.0, 0.0);
	self.frame = CGRectUnion(pointRect, _originalFrame);
	
	// _textField frame
	_textField.frame = [self convertRect:textFrame fromView:self.superview];
}

- (void)drawRect:(CGRect)rect
{
	// Only draw stretcher if incrementing
	if (_incrementing)
	{
		// Get CGContextRef
		CGContextRef context = UIGraphicsGetCurrentContext();
		UIGraphicsPushContext(context);
		
		// Set drawing properties
		CGContextSetLineWidth(context, self.lineWidth);
		[[UIColor blackColor] setStroke];
		
		// Convert _originalFrame to own coordinates (it's currently in superview's coordinates)
		// and make slightly smaller to avoid ellipse being squished at edges
		CGRect localOriginalFrame = [self convertRect:_originalFrame fromView:self.superview];
		CGRect slightlySmallerRect = CGRectInset(localOriginalFrame, self.lineWidth/2.0, self.lineWidth/2.0);
	
		// Draw ellipse
		CGContextAddEllipseInRect(context, slightlySmallerRect);
		CGContextDrawPath(context, kCGPathStroke);
		
		// Convert _touchPoint to own coordinates (it's currently in superview's coordinates)
		CGPoint localTouchPoint = [self convertPoint:_touchPoint fromView:self.superview];

		// Draw stretcher if _touchPoint is outside of _originalFrame
		if (!CGRectContainsPoint(localOriginalFrame, localTouchPoint))
		{
			// Move to point at _touchPoint's y and _originalFrame's x, in own coordinates
			CGPoint tip = CGPointMake(CGRectGetMidX(localOriginalFrame), localTouchPoint.y);
			CGContextMoveToPoint(context, tip.x, tip.y);
			
			// Calculate angles where stretcher intersects ellipse
			CGFloat angle1, angle2;
			if (localTouchPoint.y < CGRectGetMinY(localOriginalFrame))
				angle1 = M_PI_2 + self.stretcherWidth / 2.0;
			else
				angle1 = -M_PI_2 + self.stretcherWidth / 2.0;
			angle2 = angle1 - self.stretcherWidth;
			
			// Calculate corresponding radii (http://en.wikipedia.org/wiki/Ellipse#Polar_form_relative_to_center)
			CGFloat a = localOriginalFrame.size.width / 2.0;
			CGFloat b = localOriginalFrame.size.height / 2.0;
			CGFloat r1 = a * b / sqrtf(powf(b * cosf(angle1), 2.0) + powf(a * sinf(angle1), 2.0));
			CGFloat r2 = a * b / sqrtf(powf(b * cosf(angle2), 2.0) + powf(a * sinf(angle2), 2.0));
			
			// Convert polar to rectangular and move origin to center of localOriginalFrame
			CGFloat x1 = r1 * cosf(angle1) + CGRectGetMidX(localOriginalFrame);
			CGFloat y1 = -r1 * sinf(angle1) + CGRectGetMidY(localOriginalFrame);
			CGFloat x2 = r2 * cosf(angle2) + CGRectGetMidX(localOriginalFrame);
			CGFloat y2 = -r2 * sinf(angle2) + CGRectGetMidY(localOriginalFrame);
			
			// Set intersection points of stretcher with ellipse
			CGPoint intersectPoint1 = CGPointMake(x1, y1);
			CGPoint intersectPoint2 = CGPointMake(x2, y2);

/*			// Calculate points where stregher intersects ellipse
			CGPoint intersectPoint1 = CGPointMake(a * cosf(t1) + CGRectGetMidX(localOriginalFrame),
												  b * sinf(t1) + CGRectGetMidY(localOriginalFrame));
			CGPoint intersectPoint2 = CGPointMake(a * cosf(t2) + CGRectGetMidX(localOriginalFrame),
												  b * sinf(t2) + CGRectGetMidY(localOriginalFrame));*/
			
			
/*			CGFloat r = localOriginalFrame.size.width / 2.0;
			CGPoint intersectPoint1;
			if (localTouchPoint.y < CGRectGetMinY(localOriginalFrame))
				intersectPoint1 = CGPointMake(CGRectGetMidX(localOriginalFrame) - r * sinf(self.stretcherWidth/2.0),
											  CGRectGetMidY(localOriginalFrame) - r * cosf(self.stretcherWidth/2.0));
			else
				intersectPoint1 = CGPointMake(CGRectGetMidX(localOriginalFrame) - r * sinf(self.stretcherWidth/2.0),
											  CGRectGetMidY(localOriginalFrame) + r * cosf(self.stretcherWidth/2.0));
				
			// Calculate second point
			CGPoint intersectPoint2 = CGPointMake(intersectPoint1.x + 2 * r * sinf(self.stretcherWidth/2.0),
												  intersectPoint1.y);*/
			
			// Add line to first intersect point
			CGContextAddLineToPoint(context, intersectPoint1.x, intersectPoint1.y);
			CGContextAddLineToPoint(context, intersectPoint2.x, intersectPoint2.y); // TEMP: replace this with an arc
			
//			CGContextAddArcToPoint(context, intersectPoint1.x, intersectPoint1.y, intersectPoint2.x, intersectPoint2.y, localOriginalFrame.size.width / 2.0);
			// Add arc to second intersect point
/*			if (localTouchPoint.y < CGRectGetMinY(localOriginalFrame))
				CGContextAddArc(context, CGRectGetMidX(localOriginalFrame), CGRectGetMidY(localOriginalFrame),localOriginalFrame.size.width / 2.0, M_PI_4 + self.stretcherWidth / 2.0, M_PI_4 - self.stretcherWidth / 2.0, 1);
			else
				CGContextAddArc(context, CGRectGetMidX(localOriginalFrame), CGRectGetMidY(localOriginalFrame),localOriginalFrame.size.width / 2.0, - (M_PI_4 + self.stretcherWidth / 2.0), - (M_PI_4 - self.stretcherWidth / 2.0), 0);*/
			
			// Add line back to tip
			CGContextAddLineToPoint(context, tip.x, tip.y);
			
			// Draw path
			CGContextDrawPath(context, kCGPathStroke);
		}
		
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

