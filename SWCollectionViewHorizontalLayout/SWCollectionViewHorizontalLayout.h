//
//  SWCollectionViewHorizontalLayout.h
//
//  Created by Spencer Williams on 10/16/14.
//  This is free and unencumbered software released into the public domain.
//

#import <JNWCollectionView/JNWCollectionView.h>

/// The horizontal layout delegate must respond to a method that returns a particular cell's size.
/// The delegate may also respond to methods about header height, footer height and/or edge insets for a particular section.
@protocol SWCollectionViewHorizontalLayoutDelegate <NSObject>
/// @param  collectionView  The collection view
/// @param  indexPath       The index path
/// @return The size of the item at the specified index path
- (CGSize)collectionView:(JNWCollectionView *)collectionView sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional
/// @param  collectionView  The collection view
/// @param  section         The section
/// @return The header height for a particular section
- (CGFloat)collectionView:(JNWCollectionView *)collectionView widthForHeaderInSection:(NSInteger)section;
/// @param  collectionView  The collection view
/// @param  section         The section
/// @return The footer height for a particular section
- (CGFloat)collectionView:(JNWCollectionView *)collectionView widthForFooterInSection:(NSInteger)section;
/// @param  collectionView  The collection view
/// @param  section         The section
/// @return The edge insets for a particular section
- (NSEdgeInsets)collectionView:(JNWCollectionView *)collectionView edgeInsetsForSection:(NSInteger)section;

@end

/// A horizontal layout displays each section as one row, with header and footer views at the left and right ends of the row, respectively
/// TODO: Consider rewriting Staggered Grid Layout to accept a layout direction (horizontal or vertical). Then this layout becomes obselete.
@interface SWCollectionViewHorizontalLayout : JNWCollectionViewLayout
/// The layout's delegate.
@property (nonatomic, weak)   id<SWCollectionViewHorizontalLayoutDelegate> delegate;
/// The horizontal margin between items. Unused?
@property (nonatomic, assign) CGFloat itemHorizontalMargin;
@end
