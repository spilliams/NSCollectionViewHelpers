//
//  NSScrollView+TouchScroll.h
//  CurrentScience
//
//  Created by Spencer Williams on 12/15/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <AppKit/AppKit.h>

/// A scroll direction. This is used to limit a collection view to only touch-scrolling along specific axes.
typedef NS_ENUM(NSUInteger, SWTouchScrollDirection) {
    /// Horizontal
    SWTouchScrollDirectionHorizontal,
    /// Vertical
    SWTouchScrollDirectionVertical,
    /// Both horizontal and vertical
    SWTouchScrollDirectionBoth
    // "none" isn't represented here because if it doesn't scroll, why does it need to touch-scroll?
};

@protocol SWTouchScrollViewDelegate;
@protocol SWTouchScrolling <NSObject>

/// Its delegate
@property (nonatomic, weak) IBOutlet id<SWTouchScrollViewDelegate>scrollDelegate;
/// A factor to multiply "perceived" scroll distance by, to result in final view scroll distance
@property (nonatomic, assign) CGPoint scrollScaling;
/// The direction(s) the view is allowed to scroll
@property (nonatomic, assign) SWTouchScrollDirection scrollDirection;
/// This is provided here (a) because this view cannot contain gesture recognizers in IB, and because the view controller may want to send a pan GR to a collection view that the pan GR is not directly over (for instance if the pan *starts* over one collection view and proceeds over another--that pan should still be passed to the former).
/// @param  recognizer The recognizer event to handle
- (void)handlePanGesture:(NSPanGestureRecognizer *)recognizer;
/// Gives this touch-scroll collection view a new point-smoother of a specific length
/// @param  smootherLength  The length of the smoother
/// @see    SWPointSmoother
- (void)newPointSmootherWithLength:(NSInteger)smootherLength;
- (void)initializeTouchScrollable;
@end

/// A touch-scroll view delegate.
@protocol SWTouchScrollViewDelegate <NSObject>
@optional
/// Fires when the touch-scroll collection view reaches its bottom
/// @param  touchScrollView The touch-scroll collection view
- (void)touchScrollViewReachedBottom:(NSScrollView<SWTouchScrolling> *)touchScrollView;
/// Fires when the touch-scroll view is about to start scrolling
/// @param  touchScrollView The touch-scroll collection view
- (void)touchScrollViewWillStartScrolling:(NSScrollView<SWTouchScrolling> *)touchScrollView;
/// Fires when the touch-scroll view is finished scrolling
/// @param  touchScrollView The touch-scroll collection view
- (void)touchScrollViewDidEndScrolling:(NSScrollView<SWTouchScrolling> *)touchScrollView;
@end

@interface NSScrollView(TouchScroll) <NSGestureRecognizerDelegate, SWTouchScrolling>
// Returns the scroll view's content view
- (NSClipView *)clipView;
@end

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
