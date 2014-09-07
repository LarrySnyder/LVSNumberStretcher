//
//  LVSViewController.m
//  LVSNumberStretcher
//
//  Created by Larry Snyder on 8/31/14.
//  Copyright (c) 2014 Larry Snyder. All rights reserved.
//

#import "LVSViewController.h"
#import "LVSNumberStretcher.h"

@interface LVSViewController ()
{
    LVSNumberStretcher *_numberStretcher;
}

@end

@implementation LVSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

/*    // Create numberStretcher and add it as subview of numberStretcherPlaceholder
    _numberStretcher = [[LVSNumberStretcher alloc] initWithFrame:self.numberStretcherPlaceholder.bounds];
    [self.numberStretcherPlaceholder addSubview:_numberStretcher];
    
    // Set background of placeholder to clear
    self.numberStretcherPlaceholder.backgroundColor = [UIColor clearColor];*/
    
    
    LVSNumberStretcher *numberStretcher1 = [[LVSNumberStretcher alloc] initWithFrame:CGRectMake(150, 200, 60, 30)];
    [self.view addSubview:numberStretcher1];

    LVSNumberStretcher *numberStretcher2 = [[LVSNumberStretcher alloc] initWithFrame:CGRectMake(150, 300, 30, 60)];
    [self.view addSubview:numberStretcher2];
    
    LVSNumberStretcher *numberStretcher3 = [[LVSNumberStretcher alloc] initWithFrame:CGRectMake(50, 200, 50, 50)];
    numberStretcher3.textField.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:18];
    numberStretcher3.minimumIncrementSpeed = 3;
    numberStretcher3.maximumIncrementSpeed = 20;
    numberStretcher3.increment = 0.1;
    numberStretcher3.usePanGesture = NO;
    [self.view addSubview:numberStretcher3];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
