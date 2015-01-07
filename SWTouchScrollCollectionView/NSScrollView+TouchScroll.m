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

#define LOG YES
#define kEnableScrollVelocity YES

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
@dynamic  scrollScaling, scrollDirection, scrollDelegate, pointSmoother, touchStartPt, startOrigin, refreshDelegateTriggered, scrollingView; // @synthesized in the subclass

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
    self.scrollingView = self.contentView;
}

- (void)newPointSmootherWithLength:(NSInteger)smootherLength
{
    self.pointSmoother = [SWPointSmoother pointSmootherWithSmoothLength:smootherLength];
}

#pragma mark - Touch Grab Scroll stuff

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
        self.startOrigin = [(NSClipView*)self.scrollingView     	documentVisibleRect].origin;
        if (LOG) NSLog(@"[TS] start origin: %@, touch start: %@",
                       NSStringFromPoint(self.startOrigin),
                       NSStringFromPoint(self.touchStartPt));
        
    } else if (recognizer.state == NSGestureRecognizerStateEnded) {
        
        if (kEnableScrollVelocity) {
            // uniform acceleration equation
            // we have initial velocity (v0) and initial position (r0) from the GR and scroll view
            // we specify how long the deceleration should take (t), and that final velocity should be 0 (v)
            // we determine final position (r) from this and animate to it. ready? 123go!
            
            CGPoint v = [recognizer velocityInView:self.scrollingView];
            v.y = -1*v.y;
            // TODO: should we invert x too? Unsure (no test bed right now)
            CGFloat t = 0.4;
            CGPoint r0 = NSMakePoint(self.startOrigin.x - self.scrollScaling.x * (location.x - self.touchStartPt.x),
                                     self.startOrigin.y - self.scrollScaling.y * (location.y - self.touchStartPt.y));
            [self.pointSmoother addPoint:r0];
            r0 = [self.pointSmoother getSmoothedPoint];
            
            CGPoint dr = NSMakePoint(0.5 * v.x * t,
                                     0.5 * v.y * t); // dr = ((v + v0)/2)t = (v0 / 2) t
            CGPoint r = NSMakePoint(r0.x + dr.x,
                                    r0.y + dr.y); // r = r0 + dr
            if ((self.scrollDirection & SWTouchScrollDirectionVertical) == 0) r.y = 0;
            if ((self.scrollDirection & SWTouchScrollDirectionHorizontal) == 0) r.x = 0;
            
            // scroll height - current - screen size
            CGSize documentSize = ((NSView *)self.scrollingView.documentView).frame.size;
            CGPoint maxDr = NSMakePoint(documentSize.width - self.startOrigin.x - self.frame.size.width,
                                        documentSize.height - self.startOrigin.y - self.frame.size.height);
            
            NSPoint rf = NSMakePoint(r.x, r.y);
            rf.x = MIN(MAX(0, rf.x), rf.x + maxDr.x);
            rf.y = MIN(MAX(0, rf.y), rf.y + maxDr.y);
            
            if (LOG) {
                NSLog(@"[TS] pan ended");
                NSLog(@"  document size %@", NSStringFromSize(documentSize));
                NSLog(@"  frame size %@", NSStringFromSize(self.frame.size));
                NSLog(@"  current position %@", NSStringFromPoint(r0));
                NSLog(@"  max displacement %@", NSStringFromPoint(maxDr));
                NSLog(@"  velocity %@", NSStringFromPoint(v));
                NSLog(@"  displacement %@", NSStringFromPoint(dr));
                NSLog(@"  projected final position %@", NSStringFromPoint(r));
                NSLog(@"  snapped final position %@", NSStringFromPoint(rf));
            }
            
            if (dr.x == 0 && dr.y == 0) {
                if (LOG) NSLog(@"  no animation needed");
            }
            
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:t];
            [[self.scrollingView animator] setBoundsOrigin:rf];
            [NSAnimationContext endGrouping];
        }
        
        // the other stuff. not animation-related
        [self.pointSmoother clearPoints];
        
        self.refreshDelegateTriggered = NO;
        
        if (self.scrollDelegate != nil
            && [self.scrollDelegate conformsToProtocol:@protocol(SWTouchScrollViewDelegate)]
            && [self.scrollDelegate respondsToSelector:@selector(touchScrollViewDidEndScrolling:)]) {
            [self.scrollDelegate touchScrollViewDidEndScrolling:self];
        }
        
    } else  if (recognizer.state == NSGestureRecognizerStateChanged) {
        
        CGFloat dy = self.startOrigin.y - self.scrollScaling.y * (location.y - self.touchStartPt.y);
        CGFloat dx = self.startOrigin.x - self.scrollScaling.x * (location.x - self.touchStartPt.x);
        NSLog(@"[TS] scrollDirection %lu", self.scrollDirection);
        if ((self.scrollDirection & SWTouchScrollDirectionVertical) == 0) {
            dy = 0;
        }
        if ((self.scrollDirection & SWTouchScrollDirectionHorizontal) == 0) {
            dx = 0;
        }
        
        NSPoint scrollPt = NSMakePoint(dx, dy);
        
        [self.pointSmoother addPoint:scrollPt];
        NSPoint smoothedPoint = [self.pointSmoother getSmoothedPoint];
        [self.scrollingView scrollPoint:smoothedPoint];
        
        // notify delegate of scroll point
        if (self.scrollDelegate != nil &&
            [self.scrollDelegate conformsToProtocol:@protocol(SWTouchScrollViewDelegate)] &&
            [self.scrollDelegate respondsToSelector:@selector(touchScrollView:scrolledToPoint:)]) {
            [self.scrollDelegate touchScrollView:self scrolledToPoint:smoothedPoint];
        }
        
        // notify the delegate of pull-to-refresh
        if (self.scrollDelegate != nil && [self.scrollDelegate respondsToSelector:@selector(touchScrollViewReachedBottom:)]) {
            CGFloat end = self.scrollingView.documentRect.size.height - self.frame.size.height;
            CGFloat threshold = self.frame.size.height * 0.1; // the distance threshold to trigger pullToRefresh in
            if (smoothedPoint.y + threshold >= end &&
                !self.refreshDelegateTriggered) {
                if (LOG) NSLog(@"  trigger pull to refresh");
                self.refreshDelegateTriggered = YES; // debounce
                [self.scrollDelegate touchScrollViewReachedBottom:self];
            }
        }
        
    }
}

@end


