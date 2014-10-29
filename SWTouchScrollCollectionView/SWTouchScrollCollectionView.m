//
//  SWTouchScrollCollectionView.m
//
//  Created by Spencer Williams on 8/22/14.
//  This is free and unencumbered software released into the public domain.
//

#import "SWTouchScrollCollectionView.h"
#import "SWCollectionViewDocumentView.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

#define LOG YES
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

@interface SWTouchScrollCollectionView()
{
    NSPoint touchStartPt;
    NSPoint startOrigin;
    BOOL refreshDelegateTriggered;
    BOOL documentViewSet;
}
@property (nonatomic, strong) SWPointSmoother *pointSmoother;
@end

@implementation SWTouchScrollCollectionView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}
- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (!documentViewSet) {
        NSColor *backgroundColor = [NSColor whiteColor];
        if (self.scrollDelegate != nil && [self.scrollDelegate respondsToSelector:@selector(backgroundColorForTouchScrollCollectionView:)]) {
            backgroundColor = [self.scrollDelegate backgroundColorForTouchScrollCollectionView:self];
        }
        self.documentView = [[SWCollectionViewDocumentView alloc] initWithFrame:CGRectZero backgroundColor:backgroundColor];
        documentViewSet = YES;
    }
}

- (void)commonInit
{
    refreshDelegateTriggered = NO;
}

- (void)newPointSmootherWithLength:(NSInteger)smootherLength
{
    self.pointSmoother = [SWPointSmoother pointSmootherWithSmoothLength:smootherLength];
}

#define kSWEnableTouchVelocity NO
#define kSWEnablePullToRefresh YES
#define kSWPullToRefreshScreenFactor 0.1

#pragma mark - Touch Grab Scroll stuff

- (void)handlePanGesture:(NSPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self];
    
    if (recognizer.state == NSGestureRecognizerStateBegan) {
        
        if (self.scrollDelegate != nil &&
            [self.scrollDelegate conformsToProtocol:@protocol(SWTouchScrollCollectionViewDelegate)] &&
            [self.scrollDelegate respondsToSelector:@selector(touchScrollCollectionViewWillStartScrolling:)]) {
            [self.scrollDelegate touchScrollCollectionViewWillStartScrolling:self];
        }
        
        touchStartPt = location;
        startOrigin = [(NSClipView*)self documentVisibleRect].origin;
        if (LOG) NSLog(@"start origin: %@, touch start: %@",
                       NSStringFromPoint(startOrigin),
                       NSStringFromPoint(touchStartPt));
        
    } else if (recognizer.state == NSGestureRecognizerStateEnded) {
        
        if (kSWEnableTouchVelocity) {
            /* Some notes here about a future feature: the Scroll Bounce
             I don't want to have to reinvent the wheel here, but it
             appears I already am. Crud.
             
             1. when the touch ends, get the velocity in view
             2. Using the velocity and a constant "deceleration" factor, you can determine
             a. The time taken to decelerate to 0 velocity
             b. the distance travelled in that time
             3. If the final scroll point is out of bounds, update it.
             4. set up an animation block to scroll the document to that point. Make sure it uses the proper easing to feel "natural".
             5. make sure you retain a pointer or something to that animation so that a touch DURING the animation will cancel it (is this even possible?)
             */
            
            // FIXME this was written way back when the pan GR lived in the collection view, not in the controller's view.
            
            
            // determine relevant values
            CGFloat velocity = [recognizer velocityInView:self.contentView].y;
            CGFloat time = 0.2;
    //        CGFloat acceleration = -velocity/time;
            CGFloat currentY = (startOrigin.y - self.scrollScaling.y * (location.y - touchStartPt.y));
            CGFloat displacement = 0.5 * velocity * time;
            CGFloat displacedY = currentY + displacement;
            
            // scroll height - current - screen size
            CGFloat maxDisplacement = self.contentView.frame.size.height - startOrigin.y - self.frame.size.height;
            
            if (LOG) {
                NSLog(@"scroll height %f",self.contentView.frame.size.height);
                NSLog(@"container height %f",self.frame.size.height);
                NSLog(@"current position %f",currentY);
                NSLog(@"max displacement %f",maxDisplacement);
                NSLog(@"velocity %f",velocity);
                NSLog(@"displacement %f",displacement);
                NSLog(@"projected final position %f",displacedY);
            }
            
            NSString *animationKeyPath = @"position.y";
            
            if (displacement == 0) {
                if (LOG) NSLog(@"no animation needed");
            } else if (displacedY < 0) {
                if (LOG) NSLog(@"final position less than 0");
                displacedY = 0;
                CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:animationKeyPath];
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                animation.duration = time;
                
                int steps = 100;
                NSMutableArray *values = [NSMutableArray arrayWithCapacity:steps];
                double value = currentY;
                float e = 2.71;
                for (int t=0; t<steps; t++) {
                    value = 320 * pow(e, -0.055*t) * cos(0.08*t) + displacedY;
                    [values addObject:[NSNumber numberWithFloat:value]];
                }
                animation.values = values;
                
                [self.layer setValue:[NSNumber numberWithFloat:displacedY] forKey:animationKeyPath];
                [self.layer addAnimation:animation forKey:animationKeyPath];
                
            } else if (displacedY > maxDisplacement) {
                if (LOG) NSLog(@"final position greater than max");
            } else {
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:animationKeyPath];
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                animation.duration = time;
                animation.fromValue = [NSNumber numberWithFloat:currentY];
                animation.toValue = [NSNumber numberWithFloat:displacedY];
                if (LOG) NSLog(@"animating from %f to %f",[animation.fromValue floatValue],[animation.toValue floatValue]);
                [animation setDelegate:self];
                [self.layer setValue:[NSNumber numberWithFloat:displacedY] forKeyPath:animationKeyPath];
                [self.layer addAnimation:animation forKey:animationKeyPath];
            }
        }
        
        [self.pointSmoother clearPoints];
        
        refreshDelegateTriggered = NO;
        
        if (self.scrollDelegate != nil &&
            [self.scrollDelegate conformsToProtocol:@protocol(SWTouchScrollCollectionViewDelegate)] &&
            [self.scrollDelegate respondsToSelector:@selector(touchScrollCollectionViewDidEndScrolling:)]) {
            [self.scrollDelegate touchScrollCollectionViewDidEndScrolling:self];
        }
        
    } else  if (recognizer.state == NSGestureRecognizerStateChanged) {
        
        CGFloat dx = startOrigin.x - self.scrollScaling.x * (location.x - touchStartPt.x);
        if (self.scrollDirection == SWTouchScrollDirectionVertical) dx = 0;
        CGFloat dy = startOrigin.y - self.scrollScaling.y * (location.y - touchStartPt.y);
        if (self.scrollDirection == SWTouchScrollDirectionHorizontal) dy = 0;
        
        NSPoint scrollPt = NSMakePoint(dx, dy);
        
        [self.pointSmoother addPoint:scrollPt];
        NSPoint smoothedPoint = [self.pointSmoother getSmoothedPoint];
        [self.contentView scrollPoint:smoothedPoint];
        
        // notify the delegate, if necessary
        if (self.scrollDelegate != nil && [self.scrollDelegate respondsToSelector:@selector(touchScrollCollectionViewReachedBottom:)]) {
            CGFloat end = self.clipView.documentRect.size.height - self.frame.size.height;
            CGFloat threshold = self.frame.size.height * kSWPullToRefreshScreenFactor;
            if (smoothedPoint.y + threshold >= end &&
                !refreshDelegateTriggered) {
                if (LOG) NSLog(@"trigger pull to refresh");
                refreshDelegateTriggered = YES;
                [self.scrollDelegate touchScrollCollectionViewReachedBottom:self];
            }
        }
        
    }
}

@end
