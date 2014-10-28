//
//  SWTouchScrollCollectionView.h
//
//  Created by Spencer Williams on 8/22/14.
//  This is free and unencumbered software released into the public domain.
//

#import <JNWCollectionView/JNWCollectionView.h>

@class SWTouchScrollCollectionView;

typedef NS_ENUM(NSUInteger, SWTouchScrollDirection) {
    SWTouchScrollDirectionHorizontal,
    SWTouchScrollDirectionVertical,
    SWTouchScrollDirectionBoth
};

@protocol SWTouchScrollCollectionViewDelegate <NSObject>
@optional
- (void)touchScrollCollectionViewWillStartScrolling:(SWTouchScrollCollectionView *)touchScrollCollectionView;
- (void)touchScrollCollectionViewDidEndScrolling:(SWTouchScrollCollectionView *)touchScrollCollectionView;
@end

@protocol SWPullToRefreshDelegate <NSObject>
- (void)scrollViewReachedBottom:(SWTouchScrollCollectionView *)scrollView;
@end

@interface SWTouchScrollCollectionView : JNWCollectionView
@property (weak) IBOutlet id<SWTouchScrollCollectionViewDelegate>scrollDelegate;
@property (weak) IBOutlet id<SWPullToRefreshDelegate>refreshDelegate;
@property (nonatomic, assign) CGPoint scrollScaling;
@property (nonatomic, assign) SWTouchScrollDirection scrollDirection;
- (void)handlePanGesture:(NSPanGestureRecognizer *)recognizer;
- (void)newPointSmootherWithLength:(NSInteger)smootherLength;
@end
