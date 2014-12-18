//
//  SWTouchScrollView.m
//  CurrentScience
//
//  Created by Spencer Williams on 12/17/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import "SWTouchScrollView.h"

@implementation SWTouchScrollView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initializeTouchScrollable];
}

@end
