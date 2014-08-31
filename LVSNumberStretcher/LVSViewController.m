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

    // Create numberStretcher and add it as subview of numberStretcherPlaceholder
    _numberStretcher = [[LVSNumberStretcher alloc] initWithFrame:self.numberStretcherPlaceholder.bounds];
    [self.numberStretcherPlaceholder addSubview:_numberStretcher];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
