//
//  SWTouchScrollCollectionView.h
//  CurrentScience
//
//  Created by Spencer Williams on 12/16/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>
#import "NSScrollView+TouchScroll.h"

@interface SWTouchScrollCollectionView : JNWCollectionView<SWTouchScrolling>
@property (nonatomic, weak) IBOutlet id<SWTouchScrollViewDelegate>scrollDelegate;
@property (nonatomic, assign) CGPoint scrollScaling;
@property (nonatomic, assign) SWTouchScrollDirection scrollDirection;
@property (nonatomic, strong) SWPointSmoother *pointSmoother;
@property (nonatomic, assign) NSPoint touchStartPt;
@property (nonatomic, assign) NSPoint startOrigin;
@property (nonatomic, assign) BOOL refreshDelegateTriggered;
@property (nonatomic, weak) NSClipView *scrollingView;
@end
