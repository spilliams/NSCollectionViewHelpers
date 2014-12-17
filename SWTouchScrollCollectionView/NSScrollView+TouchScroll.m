//
//  NSScrollView+TouchScroll.m
//  CurrentScience
//
//  Created by Spencer Williams on 12/15/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import "NSScrollView+TouchScroll.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

#import <objc/runtime.h>

#define LOG NO

@interface SWPointSmoother ()
{
    BOOL needsCalc;
    NSPoint lastCalc;
}
/// How many touches to average (maximum)
@property (nonatomic, assign) NSInteger smoothLength;
/// The touch array
@property (nonatomic, strong) NSMutableArray *points;
- (void)commonInit;
@end

@implementation SWPointSmoother

@synthesize smoothLength, points;

+ (instancetype)pointSmootherWithSmoothLength:(NSInteger)smoothLength
{
    SWPointSmoother *p = [SWPointSmoother new];
    [p setSmoothLength:smoothLength];
    return p;
}

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}
- (void)commonInit
{
    [self setSmoothLength:1];
    lastCalc = NSMakePoint(0, 0);
}

- (void)setSmoothLength:(NSInteger)newSmoothLength
{
    // TODO copy over some values from old points?
    smoothLength = newSmoothLength;
    self.points = [NSMutableArray arrayWithCapacity:newSmoothLength];
    needsCalc = YES;
}
- (NSInteger)getSmoothLength
{
    return smoothLength;
}

- (void)addPoint:(NSPoint)point
{
    if (self.points.count == smoothLength) [self.points removeObjectAtIndex:0];
    [self.points addObject:[NSValue valueWithPoint:point]];
    needsCalc = YES;
}

- (NSPoint)getSmoothedPoint
{
    if (!needsCalc) return lastCalc;
    
    float xSum = 0;
    float ySum = 0;
    for (int i=0; i<self.points.count; i++) {
        NSPoint p = [(NSValue *)[self.points objectAtIndex:i] pointValue];
        xSum += p.x;
        ySum += p.y;
    }
    
    needsCalc = NO;
    
    lastCalc = NSMakePoint(xSum/self.points.count,
                           ySum/self.points.count);
    return lastCalc;
}

- (void)clearPoints
{
    self.points = [NSMutableArray arrayWithCapacity:smoothLength];
}

@end

@implementation NSScrollView(TouchScroll)
@dynamic  scrollScaling, scrollDirection, scrollDelegate, pointSmoother; // @synthesized in the subclass

#pragma mark - Associated Objects

// http://nshipster.com/associated-objects/

static char kStartOriginKey;

- (void)setTouchStartPt:(NSPoint)touchStartPt
{
    objc_setAssociatedObject(self, &@selector(touchStartPt), [NSValue valueWithPoint:touchStartPt], OBJC_ASSOCIATION_ASSIGN);
}
- (NSPoint)touchStartPt
{
    return [((NSValue *)objc_getAssociatedObject(self, &@selector(touchStartPt))) pointValue];
}

- (void)setStartOrigin:(NSPoint)startOrigin
{
    objc_setAssociatedObject(self, &kStartOriginKey, [NSValue valueWithPoint:startOrigin], OBJC_ASSOCIATION_ASSIGN);
}
- (NSPoint)startOrigin
{
    NSValue *startOriginValue = objc_getAssociatedObject(self, &kStartOriginKey);
    return [startOriginValue pointValue];
}

- (void)setRefreshDelegateTriggered:(BOOL)refreshDelegateTriggered
{
    objc_setAssociatedObject(self, &@selector(refreshDelegateTriggered), [NSNumber numberWithBool:refreshDelegateTriggered], OBJC_ASSOCIATION_ASSIGN);
}
- (BOOL)refreshDelegateTriggered
{
    return [((NSNumber *)objc_getAssociatedObject(self, &@selector(refreshDelegateTriggered))) boolValue];
}

#pragma mark - Initialization

- (void)initializeTouchScrollable {
    self.refreshDelegateTriggered = NO;
    
    BOOL found = NO;
    for (NSGestureRecognizer *gr in self.gestureRecognizers) {
        if ([gr isKindOfClass:[NSPanGestureRecognizer class]]
            && gr.action == @selector(handlePanGesture:)) {
            found = YES;
        }
    }
    if (!found) {
        NSPanGestureRecognizer *panGR = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [panGR setDelegate:self];
        [self addGestureRecognizer:panGR];
    }
    
    self.startOrigin = NSMakePoint(0, 0);
}

- (void)newPointSmootherWithLength:(NSInteger)smootherLength
{
    self.pointSmoother = [SWPointSmoother pointSmootherWithSmoothLength:smootherLength];
}

#pragma mark - Touch Grab Scroll stuff

#define kSWEnableTouchVelocity NO
#define kSWEnablePullToRefresh YES
#define kSWPullToRefreshScreenFactor 0.1

- (void)handlePanGesture:(NSPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self];
    
    if (recognizer.state == NSGestureRecognizerStateBegan) {
        
        if (self.scrollDelegate != nil &&
            [self.scrollDelegate conformsToProtocol:@protocol(SWTouchScrollViewDelegate)] &&
            [self.scrollDelegate respondsToSelector:@selector(touchScrollViewWillStartScrolling:)]) {
            [self.scrollDelegate touchScrollViewWillStartScrolling:self];
        }
        
        self.touchStartPt = location;
        self.startOrigin = [(NSClipView*)self documentVisibleRect].origin;
        if (LOG) NSLog(@"[TS] start origin: %@, touch start: %@",
                       NSStringFromPoint(self.startOrigin),
                       NSStringFromPoint(self.touchStartPt));
        
    } else if (recognizer.state == NSGestureRecognizerStateEnded) {
        
        [self.pointSmoother clearPoints];
        
        self.refreshDelegateTriggered = NO;
        
        if (self.scrollDelegate != nil &&
            [self.scrollDelegate conformsToProtocol:@protocol(SWTouchScrollViewDelegate)] &&
            [self.scrollDelegate respondsToSelector:@selector(touchScrollViewDidEndScrolling:)]) {
            [self.scrollDelegate touchScrollViewDidEndScrolling:self];
        }
        
    } else  if (recognizer.state == NSGestureRecognizerStateChanged) {
        
        CGFloat dx = self.startOrigin.x - self.scrollScaling.x * (location.x - self.touchStartPt.x);
        if (self.scrollDirection == SWTouchScrollDirectionVertical) dx = 0;
        CGFloat dy = self.startOrigin.y - self.scrollScaling.y * (location.y - self.touchStartPt.y);
        if (self.scrollDirection == SWTouchScrollDirectionHorizontal) dy = 0;
        
        NSPoint scrollPt = NSMakePoint(dx, dy);
        
        [self.pointSmoother addPoint:scrollPt];
        NSPoint smoothedPoint = [self.pointSmoother getSmoothedPoint];
        [self.contentView scrollPoint:smoothedPoint];
        
        // notify the delegate, if necessary
        if (self.scrollDelegate != nil && [self.scrollDelegate respondsToSelector:@selector(touchScrollViewReachedBottom:)]) {
            CGFloat end = self.contentView.documentRect.size.height - self.frame.size.height;
            CGFloat threshold = self.frame.size.height * kSWPullToRefreshScreenFactor;
            if (smoothedPoint.y + threshold >= end &&
                !self.refreshDelegateTriggered) {
                if (LOG) NSLog(@"  trigger pull to refresh");
                self.refreshDelegateTriggered = YES;
                [self.scrollDelegate touchScrollViewReachedBottom:self];
            }
        }
        
    }
}

@end


