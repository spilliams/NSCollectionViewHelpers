//
//  SWTouchScrollCollectionView.h
//
//  Created by Spencer Williams on 8/22/14.
//  This is free and unencumbered software released into the public domain.
//

#import "SWCollectionView.h"

@class SWTouchScrollCollectionView;

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

/// A touch-scroll collection view delegate.
@protocol SWTouchScrollCollectionViewDelegate <NSObject>
@optional
/// Fires when the touch-scroll collection view reaches its bottom
/// @param  touchScrollCollectionView The touch-scroll collection view
- (void)touchScrollCollectionViewReachedBottom:(SWTouchScrollCollectionView *)touchScrollCollectionView;
/// Fires when the touch-scroll collection view is about to start scrolling
/// @param  touchScrollCollectionView The touch-scroll collection view
- (void)touchScrollCollectionViewWillStartScrolling:(SWTouchScrollCollectionView *)touchScrollCollectionView;
/// Fires when the touch-scroll collection view is finished scrolling
/// @param  touchScrollCollectionView The touch-scroll collection view
- (void)touchScrollCollectionViewDidEndScrolling:(SWTouchScrollCollectionView *)touchScrollCollectionView;
@end

/// A collection view that may be scrolled by a click-drag gesture in addition to a normal scroll gesture
@interface SWTouchScrollCollectionView : SWCollectionView <NSGestureRecognizerDelegate>
/// Its delegate
@property (weak) IBOutlet id<SWTouchScrollCollectionViewDelegate>scrollDelegate;
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
