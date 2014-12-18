//
//  SWTouchScrollView.h
//  CurrentScience
//
//  Created by Spencer Williams on 12/17/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSScrollView+TouchScroll.h"

@interface SWTouchScrollView : NSScrollView<SWTouchScrolling>
@property (nonatomic, weak) IBOutlet id<SWTouchScrollViewDelegate>scrollDelegate;
@property (nonatomic, assign) CGPoint scrollScaling;
@property (nonatomic, assign) SWTouchScrollDirection scrollDirection;
@property (nonatomic, strong) SWPointSmoother *pointSmoother;
@property (nonatomic, assign) NSPoint touchStartPt;
@property (nonatomic, assign) NSPoint startOrigin;
@property (nonatomic, assign) BOOL refreshDelegateTriggered;

@end
