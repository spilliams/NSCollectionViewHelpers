//
//  SWTouchScrollWebView.h
//  CurrentScience
//
//  Created by Spencer Williams on 12/17/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "NSScrollView+TouchScroll.h"

@interface SWTouchScrollWebView : WebView <NSGestureRecognizerDelegate, SWTouchScrollViewDelegate>
- (NSScrollView *)webScrollView;
/// defaults to 25
@property (nonatomic, assign) NSInteger pointSmootherLength;
/// defaults to a [1,1] point
@property (nonatomic, assign) CGPoint scrollScaling;
/// defaults to Vertical | Horizontal
@property (nonatomic, assign) SWTouchScrollDirection touchScrollDirection;
- (void)setScrollerKnobStyle:(NSScrollerKnobStyle)knobStyle;
@end
