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
@end
