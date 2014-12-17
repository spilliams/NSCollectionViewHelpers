//
//  SWTouchScrollCollectionView.m
//  CurrentScience
//
//  Created by Spencer Williams on 12/16/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import "SWTouchScrollCollectionView.h"

@implementation SWTouchScrollCollectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initializeTouchScrollable];
}

@end
