//
//  NSScrollView+TouchScroll.h
//  CurrentScience
//
//  Created by Spencer Williams on 12/15/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <AppKit/AppKit.h>

/// A scroll direction. This is used to limit a collection view to only touch-scrolling along specific axes.
typedef NS_OPTIONS(NSUInteger, SWTouchScrollDirection) {
    /// Vertical
    SWTouchScrollDirectionVertical = 1 << 0,
    /// Horizontal
    SWTouchScrollDirectionHorizontal = 1 << 1
};

/// An object that keeps track of a moving average of a certain number of points
/// Moving average is calculated lazily (that is, only when `-getSmoothedPoint` is called, and only then if points were added since the last call.
@interface SWPointSmoother : NSObject
/// @param  smoothLength The desired length, or number of points to average, of the smoother
/// @return A new SWPointSmoother with a specific length
+ (instancetype)pointSmootherWithSmoothLength:(NSInteger)smoothLength;

/// @param  newSmoothLength The new number of points to average over
- (void)setSmoothLength:(NSInteger)newSmoothLength;
/// @return The smooth length
- (NSInteger)getSmoothLength;
/// Adds a point to the smoother.
/// @param  point The point to add.
- (void)addPoint:(NSPoint)point;
/// @return The average of all points
- (NSPoint)getSmoothedPoint;
/// Clears the smoother of all points
- (void)clearPoints;

@end

@protocol SWTouchScrollViewDelegate;
@protocol SWTouchScrolling <NSObject>
/// A state variable containing the point at the start of the touch-scroll, in the scrolling view.
@property (nonatomic, assign) NSPoint touchStartPt;
/// A state variable containing the origin of the scrolling view at the start of the touch-scroll.
@property (nonatomic, assign) NSPoint startOrigin;
/// A state variable tracking whether or not the refresh delegate has been notified of a refresh.
/// This is kept so that the refresh delegate is not notified for every single call to `handlePanGesture`
@property (nonatomic, assign) BOOL refreshDelegateTriggered;
/// The view that will be controlled by the touch-scroll (pan gesture). Defaults to `self.contentView`
@property (nonatomic, weak) NSClipView *scrollingView;
/// The receiver's scroll delegate
@property (nonatomic, weak) IBOutlet id<SWTouchScrollViewDelegate>scrollDelegate;
/// A point smoother to allow the scroll to operate on a moving average. Implemented due to particular hardware issues.
@property (nonatomic, strong) SWPointSmoother *pointSmoother;
/// A factor to multiply "perceived" scroll distance by, to result in final view scroll distance
@property (nonatomic, assign) CGPoint scrollScaling;
/// The direction(s) the view is allowed to scroll
@property (nonatomic, assign) SWTouchScrollDirection scrollDirection;
/// Gives this touch-scroll collection view a new point-smoother of a specific length
/// @param  smootherLength  The length of the smoother
/// @see    SWPointSmoother
- (void)newPointSmootherWithLength:(NSInteger)smootherLength;
/// Since we can't really override methods in a category, we need to call this from classes that conform to this protocol. Recommend calling this during `-awakeFromNib:` or similar.
- (void)initializeTouchScrollable;
@end

/// A touch-scroll view delegate.
@protocol SWTouchScrollViewDelegate <NSObject>
@optional
/// Fires when the touch-scroll collection view reaches its bottom
/// @param  touchScrollView The touch-scroll view
- (void)touchScrollViewReachedBottom:(NSScrollView<SWTouchScrolling> *)touchScrollView;
/// Fires when the touch-scroll view is about to start scrolling
/// @param  touchScrollView The touch-scroll view
- (void)touchScrollViewWillStartScrolling:(NSScrollView<SWTouchScrolling> *)touchScrollView;
/// Fires when the touch-scroll view is finished scrolling
/// @param  touchScrollView The touch-scroll view
- (void)touchScrollViewDidEndScrolling:(NSScrollView<SWTouchScrolling> *)touchScrollView;
/// Fires during the pan gesture of a touch-scroll interaction
/// @param  touchScrollView The touch-scroll view
/// @param  scrollPoint     The point scrolled-to
- (void)touchScrollView:(NSScrollView<SWTouchScrolling> *)touchScrollView scrolledToPoint:(NSPoint)scrollPoint;
@end

@interface NSScrollView(TouchScroll) <NSGestureRecognizerDelegate, SWTouchScrolling>
@end
