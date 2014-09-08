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
	BOOL _incrementing;
	CGFloat _currentIncrementSpeed;		// increments per second (+ = increasing, - = decreasing)
	BOOL _nextIncrementScheduled;		// has next increment been scheduled?
	BOOL _editing;
//	UIView *_circularFrame;
	CGRect _originalFrame;				// original frame of control, in superview's coordinates
	CGRect _actualEllipseFrame;			// frame for ellipse to be drawn around text field, in superview's coordinates
	CGPoint _touchPoint;				// point currently being touched during stretch, in superview's coordinates
}

/*
 Frames: When not stretching, frame = frame assigned when calling initWithFrame: or 
 by setting self.frame. When stretching:
	self.frame is changed to encompass control
	_originalFrame = original (unstretched) frame
	_actualEllipseFrame = frame for ellipse drawn around text field -- equals self.circleFrame if provided by user, 
		or smallest square containing text field frame if self.circleFrame = CGRectZero
 */

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		// Create text field
		_textField = [[UITextField alloc] initWithFrame:self.bounds]; //CGRectInset(self.bounds, 5, 5)];
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
		self.circleFrame = CGRectZero;
		self.stretcherWidth = M_PI / 4.0;
		self.circleLineWidth = 1.0;
		self.circleLineColor = [UIColor blackColor];
		self.circleFillColor = [UIColor whiteColor];
		self.stretcherLineColor = [UIColor blackColor];
		self.stretcherFillColor = [UIColor blackColor];
		self.usePanGesture = YES;
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
//		_originalFrame = self.frame;
								
		// Double-tap recognizer
		// basically uses the method here: http://stackoverflow.com/questions/20420784/double-tap-uitextview
		UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
		doubleTapRecognizer.numberOfTapsRequired = 2;
		doubleTapRecognizer.numberOfTouchesRequired = 1;
//		doubleTapRecognizer.delaysTouchesBegan = YES;
		doubleTapRecognizer.delegate = self;
		[self addGestureRecognizer:doubleTapRecognizer];
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

- (void)setUsePanGesture:(BOOL)panGestureStretches
{
	_usePanGesture = panGestureStretches;
	
	if (_usePanGesture)
	{
		// Remove long-press gesture recognizer, if any
		for (UIGestureRecognizer *gesture in self.gestureRecognizers)
			if ([gesture isMemberOfClass:[UILongPressGestureRecognizer class]])
				[self removeGestureRecognizer:gesture];

		// Set up pan gesture recognizer
		UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleStretch:)];
		panRecognizer.minimumNumberOfTouches = 1;
		panRecognizer.maximumNumberOfTouches = 1;
		[self addGestureRecognizer:panRecognizer];
	}
	else
	{
		// Remove pan gesture recognizer, if any
		for (UIGestureRecognizer *gesture in self.gestureRecognizers)
			if ([gesture isMemberOfClass:[UIPanGestureRecognizer class]])
				[self removeGestureRecognizer:gesture];
		
		// Set up long-press gesture recognizer
		UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleStretch:)];
		longPressRecognizer.numberOfTapsRequired = 0;
		longPressRecognizer.numberOfTouchesRequired = 1;
		longPressRecognizer.delegate = self;
		[self addGestureRecognizer:longPressRecognizer];
	}
}

#pragma mark - Gesture Handling

/*- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
	// Pass gesture recognizer to handleStretch:
	[self handleStretch:gesture];
}

- (void)handlePress:(UILongPressGestureRecognizer *)gesture
{
	// Pass gesture recognizer to handleStretch:
	[self handleStretch:gesture];
}*/

- (void)handleStretch:(UIGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		// Set _originalFrame
		_originalFrame = self.frame;
		
		// Set _actualEllipseFrame
		if ((self.circleFrame.size.width == 0.0) && (self.circleFrame.size.height == 0.0))
		{
			if (_originalFrame.size.width < _originalFrame.size.height)
				// Frame is taller than wide
				_actualEllipseFrame = CGRectMake(CGRectGetMinX(_originalFrame) - (_originalFrame.size.height - _originalFrame.								size.width) / 2.0,
												 CGRectGetMinY(_originalFrame),
												 _originalFrame.size.height, _originalFrame.size.height);
			else
				// Frame is wider than tall
				_actualEllipseFrame = CGRectMake(CGRectGetMinX(_originalFrame),
												 CGRectGetMinY(_originalFrame) - (_originalFrame.size.width - _originalFrame.size.height) / 2.0,
												 _originalFrame.size.width, _originalFrame.size.width);
		}
		else
			_actualEllipseFrame = self.circleFrame;
	}
	
	if ((gesture.state == UIGestureRecognizerStateBegan) ||
		(gesture.state == UIGestureRecognizerStateChanged))
	{
		// Get touch point in superview's coordinates
		_touchPoint = [gesture locationInView:self.superview];
		
		// TODO: allow user to specify "up" direction and make everything relative to that
		
		// Calculate distance to nearest (top/bottom) edge of ellipse frame and increment speed
		CGFloat touchDistance; // +/-
		if (_touchPoint.y < CGRectGetMinY(_actualEllipseFrame))
		{
			// Touch is above frame: touchDistance and _currentIncrementSpeed will be >0
			touchDistance = CGRectGetMinY(_actualEllipseFrame) - _touchPoint.y;
			_currentIncrementSpeed = self.maximumIncrementSpeed * touchDistance / self.maximumDistance;
			_currentIncrementSpeed = MIN(self.maximumIncrementSpeed, MAX(_currentIncrementSpeed, self.minimumIncrementSpeed));
		}
		else if (_touchPoint.y > CGRectGetMaxY(_actualEllipseFrame))
		{
			// Touch is below frame: touchDistance and _currentIncrementSpeed will be <0
			touchDistance = CGRectGetMaxY(_actualEllipseFrame) - _touchPoint.y;
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
		[self resetFrames];
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
	New frame is set equal to union of _actualEllipseFrame and touchPoint.
	touchPoint must be in superview's coordinates. */
- (void)updateFramesForTouchPoint:(CGPoint)touchPoint;
{
	// Remember current frame for _textField, in superview's coordinates
	CGRect textFrame = [self.superview convertRect:_textField.frame fromView:self];
	
	// self frame
	CGRect pointRect = CGRectMake(CGRectGetMidX(_actualEllipseFrame), touchPoint.y, 0.0, 0.0);
	self.frame = CGRectUnion(pointRect, _actualEllipseFrame);
	
	// _textField frame
	_textField.frame = [self convertRect:textFrame fromView:self.superview];
}

/* Resets frames of self and _textField to original values. */
- (void)resetFrames;
{
	// Remember current frame for _textField, in superview's coordinates
	CGRect textFrame = [self.superview convertRect:_textField.frame fromView:self];
	
	// self frame
	self.frame = _originalFrame;
	
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
		
		// Convert _actualEllipseFrame to own coordinates (it's currently in superview's coordinates)
		CGRect localEllipseFrame = [self convertRect:_actualEllipseFrame fromView:self.superview];
		
		// Convert _touchPoint to own coordinates (it's currently in superview's coordinates)
		CGPoint localTouchPoint = [self convertPoint:_touchPoint fromView:self.superview];

		// Draw stretcher if _touchPoint is outside of _originalFrame
		if (!CGRectContainsPoint(localEllipseFrame, localTouchPoint))
		{
			// Set drawing properties
			CGContextSetLineWidth(context, self.stretcherLineWidth);
			[self.stretcherLineColor setStroke];
			[self.stretcherFillColor setFill];
			
			// Move to point at _touchPoint's y and _originalFrame's x, in own coordinates
			CGPoint tip = CGPointMake(CGRectGetMidX(localEllipseFrame), localTouchPoint.y);
			
			// Calculate angles where stretcher intersects ellipse
			CGFloat angle1, angle2;
			if (localTouchPoint.y < CGRectGetMinY(localEllipseFrame))
				angle1 = M_PI_2 + self.stretcherWidth / 2.0;
			else
				angle1 = -M_PI_2 + self.stretcherWidth / 2.0;
			angle2 = angle1 - self.stretcherWidth;
			
			// Calculate corresponding radii (http://en.wikipedia.org/wiki/Ellipse#Polar_form_relative_to_center)
			CGFloat a = localEllipseFrame.size.width / 2.0;
			CGFloat b = localEllipseFrame.size.height / 2.0;
			CGFloat r1 = a * b / sqrtf(powf(b * cosf(angle1), 2.0) + powf(a * sinf(angle1), 2.0));
			CGFloat r2 = a * b / sqrtf(powf(b * cosf(angle2), 2.0) + powf(a * sinf(angle2), 2.0));
			
			// Convert polar to rectangular and move origin to center of localEllipseFrame
			CGFloat x1 = r1 * cosf(angle1) + CGRectGetMidX(localEllipseFrame);
			CGFloat y1 = -r1 * sinf(angle1) + CGRectGetMidY(localEllipseFrame);
			CGFloat x2 = r2 * cosf(angle2) + CGRectGetMidX(localEllipseFrame);
			CGFloat y2 = -r2 * sinf(angle2) + CGRectGetMidY(localEllipseFrame);
			
			// Set intersection points of stretcher with ellipse
			CGPoint intersectPoint1 = CGPointMake(x1, y1);
			CGPoint intersectPoint2 = CGPointMake(x2, y2);
			
			// Calculate control points for first stretcher curve
			// Template: (-2.3, 0.4) (-0.5, 1.3) (-0.3, 3.7) (0.0, 8.0)
			CGFloat xScale = (CGRectGetMidX(localEllipseFrame) - intersectPoint1.x) / (0.0 - (-2.3));
			CGFloat yScale = (tip.y - intersectPoint1.y) / (8.0 - 0.4);
			CGPoint controlPoint1 = CGPointMake(xScale * (-0.5 - (-2.3)) + intersectPoint1.x,
												yScale * (1.3 - 0.4) + intersectPoint1.y);
			CGPoint controlPoint2 = CGPointMake(xScale * (-0.3 - (-2.3)) + intersectPoint1.x,
												yScale * (3.7 - 0.4) + intersectPoint1.y);
			
			// Add first Bezier curve for stretcher
			CGContextMoveToPoint(context, intersectPoint1.x, intersectPoint1.y);
			CGContextAddCurveToPoint(context, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, tip.x, tip.y);
			
			// Calculate control points for second stretcher curve
			// Template: (2.3, 0.4) (0.5, 1.3) (0.3, 3.7) (0.0, 8.0)
			xScale = (intersectPoint2.x - CGRectGetMidX(localEllipseFrame)) / (2.3 - 0.0);
			yScale = (tip.y - intersectPoint2.y) / (8.0 - 0.4);
			controlPoint1 = CGPointMake(xScale * (0.3 - 2.3) + intersectPoint2.x,
										yScale * (3.7 - 0.4) + intersectPoint2.y);
			controlPoint2 = CGPointMake(xScale * (0.5 - 2.3) + intersectPoint2.x,
												yScale * (1.3 - 0.4) + intersectPoint2.y);
			
			// Add second Bezier curve for stretcher
//			CGContextMoveToPoint(context, intersectPoint2.x, intersectPoint2.y);
			CGContextAddCurveToPoint(context, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, intersectPoint2.x, intersectPoint2.y);
			
			// Draw path
			CGContextClosePath(context);
			CGContextFillPath(context);
		}
		
		// Set drawing properties
		CGContextSetLineWidth(context, self.circleLineWidth);
		[self.circleLineColor setStroke];
		[self.circleFillColor setFill];
		
		// Draw ellipse
		CGRect slightlySmallerRect = CGRectInset(localEllipseFrame, self.circleLineWidth/2.0, self.circleLineWidth/2.0);
		CGContextFillEllipseInRect(context, slightlySmallerRect);
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	// Without this, long-press recognizer doesn't fire if press occurs on text field.
	// TODO: Is this safe?
	// Might this be returning YES for other events, when it should be returning NO?
	// How can I get the "default" value of gestureRecognizer:shouldReceiveTouch: if this is not the
	// long-press recognizer?
	return YES;
}

@end

