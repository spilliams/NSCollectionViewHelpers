//
//  SWCollectionViewStaggeredGridLayout.h
//
//  Created by Spencer Williams on 9/29/14.
//  This is free and unencumbered software released into the public domain.
//

#import <JNWCollectionView/JNWCollectionView.h>

/// Staggered grid layout delegates should respond to methods about the grid layout values
@protocol SWCollectionViewStaggeredGridLayoutDelegate <NSObject>
- (NSInteger)numberOfColumnsInCollectionView:(JNWCollectionView *)collectionView section:(NSInteger)section;
- (CGFloat)collectionView:(JNWCollectionView *)collectionView
       heightForCellWidth:(CGFloat)cellWidth
              atIndexPath:(NSIndexPath *)indexPath;
@end

/** The Staggered Grid Layout has a few features that a normal grid layout does not:
 
 - Cell width is not delegated directly, it's derived from the number of columns.
 - Each section may have its own number of columns.
 - Cells may each have their own height. Each cell will lay out in the shortest column (after giving room for vertical spacing)
 
 */
@interface SWCollectionViewStaggeredGridLayout : JNWCollectionViewGridLayout
/// The staggered grid delegate
@property (nonatomic, unsafe_unretained) id<SWCollectionViewStaggeredGridLayoutDelegate> staggeredDelegate;

@end
