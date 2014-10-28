//
//  SWCollectionViewHorizontalLayout.h
//
//  Created by Spencer Williams on 10/16/14.
//  This is free and unencumbered software released into the public domain.
//

#import <JNWCollectionView/JNWCollectionView.h>

@protocol SWCollectionViewHorizontalLayoutDelegate <NSObject>

- (CGSize)collectionView:(JNWCollectionView *)collectionView sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)collectionView:(JNWCollectionView *)collectionView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)collectionView:(JNWCollectionView *)collectionView heightForFooterInSection:(NSInteger)section;
- (NSEdgeInsets)collectionView:(JNWCollectionView *)collectionView edgeInsetsForSection:(NSInteger)section;

@end

@interface SWCollectionViewHorizontalLayout : JNWCollectionViewLayout
@property (nonatomic, weak)   id<SWCollectionViewHorizontalLayoutDelegate> delegate;
@property (nonatomic, assign) CGFloat itemHorizontalMargin;
@end
