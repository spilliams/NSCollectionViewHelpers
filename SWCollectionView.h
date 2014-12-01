//
//  SWCollectionView.h
//  CurrentScience
//
//  Created by Spencer Williams on 12/1/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

@class SWCollectionView;

@protocol SWCollectionViewDelegate <NSObject>
/// @param  touchScrollCollectionView The touch-scroll collection view
/// @return The touch-scroll collection view's background color
- (NSColor *)backgroundColorForCollectionView:(SWCollectionView *)collectionView;
@end

@interface SWCollectionView : JNWCollectionView
@property (weak) IBOutlet id<SWCollectionViewDelegate>sw_delegate;
@end
