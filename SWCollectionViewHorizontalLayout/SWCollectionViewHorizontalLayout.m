//
//  SWCollectionViewHorizontalLayout.m
//
//  Created by Spencer Williams on 10/16/14.
//  This is free and unencumbered software released into the public domain.
//

#import "SWCollectionViewHorizontalLayout.h"

#define LOG NO

typedef struct {
    CGPoint origin;
    CGSize size;
} SWCollectionViewHorizontalLayoutItemInfo;

typedef NS_ENUM(NSInteger, SWSectionEdge) {
    SWSectionEdgeLeft,
    SWSectionEdgeRight
};

// Each section is a row
@interface SWCollectionViewHorizontalLayoutSection : NSObject
@property (nonatomic, assign) CGFloat offset;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, assign) SWCollectionViewHorizontalLayoutItemInfo *itemInfo;

- (instancetype)initWithNumberOfItems:(NSInteger)numberOfItems;
@end

@implementation SWCollectionViewHorizontalLayoutSection
- (instancetype)initWithNumberOfItems:(NSInteger)numberOfItems {
    self = [super init];
    if (self == nil) return nil;
    _numberOfItems = numberOfItems;
    self.itemInfo = calloc(numberOfItems, sizeof(SWCollectionViewHorizontalLayoutItemInfo));
    return self;
}

@end

@interface SWCollectionViewHorizontalLayout()
@property (nonatomic, strong) NSMutableArray *sections;
@end

@implementation SWCollectionViewHorizontalLayout

- (NSMutableArray *)sections {
    if (_sections == nil) {
        _sections = [NSMutableArray array];
    }
   
    return _sections;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return NO;
}

- (void)prepareLayout
{
    if (LOG) {
        NSLog(@"");
        NSLog(@"");
        NSLog(@"");
        NSLog(@"");
        NSLog(@"");
        NSLog(@"");
        NSLog(@"");
        NSLog(@"");
        NSLog(@"preparing layout");
    }
    [self.sections removeAllObjects];
    
    NSUInteger numberOfSections = [self.collectionView numberOfSections];
    CGFloat totalHeight = 0;
    
    for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        if (LOG) NSLog(@"  section %i", (int)sectionIndex);
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:sectionIndex];
        NSEdgeInsets sectionInsets = [self edgeInsetsForSection:sectionIndex];
        
        SWCollectionViewHorizontalLayoutSection *section = [[SWCollectionViewHorizontalLayoutSection alloc] initWithNumberOfItems:numberOfItems];
        section.offset = totalHeight;
        section.headerHeight = [self heightForHeaderInSection:sectionIndex];
        section.footerHeight = [self heightForFooterInSection:sectionIndex];
        section.index = sectionIndex;
        
        CGFloat maxItemHeight = 0;
        
        for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
            if (LOG) NSLog(@"    item %i", (int)itemIndex);
            NSIndexPath *indexPath = [NSIndexPath jnw_indexPathForItem:itemIndex inSection:sectionIndex];
            CGSize itemSize = [self.delegate collectionView:self.collectionView sizeForItemAtIndexPath:indexPath];
            maxItemHeight = MAX(maxItemHeight, itemSize.height);
            section.itemInfo[itemIndex].size = itemSize;
            section.itemInfo[itemIndex].origin = CGPointMake(sectionInsets.left + itemIndex * ( + itemSize.width),
                                                             sectionInsets.top);
        } // item loop
        
        section.height = maxItemHeight + sectionInsets.top + sectionInsets.bottom;
        totalHeight += section.height + section.headerHeight + section.footerHeight;
        [self.sections addObject:section];
        
    } // section loop
}

- (JNWCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SWCollectionViewHorizontalLayoutSection *section = self.sections[indexPath.jnw_section];
    SWCollectionViewHorizontalLayoutItemInfo itemInfo = section.itemInfo[indexPath.jnw_item];
    CGFloat offset = section.offset;
    
    JNWCollectionViewLayoutAttributes *attributes = [[JNWCollectionViewLayoutAttributes alloc] init];
    attributes.frame = CGRectMake(itemInfo.origin.x, itemInfo.origin.y + offset, itemInfo.size.width, itemInfo.size.height);
    attributes.alpha = 1.f;
    return attributes;
}

- (JNWCollectionViewLayoutAttributes *)layoutAttributesForSupplementaryItemInSection:(NSInteger)sectionIndex kind:(NSString *)kind
{
    SWCollectionViewHorizontalLayoutSection *section = self.sections[sectionIndex];
    CGFloat width = self.collectionView.visibleSize.width;
    CGRect frame = CGRectZero;
    
    if ([kind isEqualToString:JNWCollectionViewGridLayoutHeaderKind]) {
        frame = CGRectMake(0, section.offset, width, section.headerHeight);
    } else if ([kind isEqualToString:JNWCollectionViewGridLayoutFooterKind]) {
        frame = CGRectMake(0, section.offset + section.height, width, section.footerHeight);
    }
    
    JNWCollectionViewLayoutAttributes *attributes = [JNWCollectionViewLayoutAttributes new];
    attributes.frame = frame;
    attributes.alpha = 1.f;
    return attributes;
}

- (NSArray *)indexPathsForItemsInRect:(CGRect)rect {
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    for (SWCollectionViewHorizontalLayoutSection *section in self.sections) {
        // use a binary search to get the bounds of the index paths
        NSInteger leftItem = [self nearestIntersectingItemInSection:section inRect:rect edge:SWSectionEdgeLeft];
        NSInteger rightItem = [self nearestIntersectingItemInSection:section inRect:rect edge:SWSectionEdgeRight];
        
        for (NSInteger item = leftItem; item <= rightItem; item++) {
            [indexPaths addObject:[NSIndexPath jnw_indexPathForItem:item inSection:section.index]];
        }
    }
    
    return indexPaths;
}

- (NSIndexPath *)indexPathForNextItemInDirection:(JNWCollectionViewDirection)direction currentIndexPath:(NSIndexPath *)currentIndexPath {
    NSIndexPath *newIndexPath = currentIndexPath;
    
    if (direction == JNWCollectionViewDirectionLeft) {
        newIndexPath = [self.collectionView indexPathForNextSelectableItemBeforeIndexPath:currentIndexPath];
    } else if (direction == JNWCollectionViewDirectionRight) {
        newIndexPath = [self.collectionView indexPathForNextSelectableItemAfterIndexPath:currentIndexPath];
    }
    
    return newIndexPath;
}

#pragma mark - Private Helpers

- (NSInteger)nearestIntersectingItemInSection:(SWCollectionViewHorizontalLayoutSection *)section inRect:(CGRect)containingRect edge:(SWSectionEdge)edge
{
    NSInteger low = 0;
    NSInteger high = section.numberOfItems - 1;
    NSInteger mid = 0;
    
    CGFloat edgeLocation = (edge == SWSectionEdgeLeft ? containingRect.origin.x : containingRect.origin.x + containingRect.size.width);
    
    while (low <= high) {
        mid = (low + high) / 2;
        SWCollectionViewHorizontalLayoutItemInfo midInfo = section.itemInfo[mid];

        if (edge == SWSectionEdgeLeft) {
            if (midInfo.origin.x > edgeLocation) {
                high = mid-1;
            } else if (midInfo.origin.x + midInfo.size.width < edgeLocation) {
                low = mid+1;
            } else {
                return mid;
            }
        } else { // SWSectionEdgeRight
            if (midInfo.origin.x > edgeLocation) {
                high = mid-1;
            } else if (midInfo.origin.x + midInfo.size.width < edgeLocation) {
                low = mid+1;
            } else {
                return mid;
            }
        }
    }
    
    return mid;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)sectionIndex
{
    if (self.delegate != nil &&
        [self.delegate conformsToProtocol:@protocol(SWCollectionViewHorizontalLayoutDelegate)] &&
        [self.delegate respondsToSelector:@selector(collectionView:heightForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView heightForHeaderInSection:sectionIndex];
    }
    return 0;
}

- (CGFloat)heightForFooterInSection:(NSInteger)sectionIndex
{
    if (self.delegate != nil &&
        [self.delegate conformsToProtocol:@protocol(SWCollectionViewHorizontalLayoutDelegate)] &&
        [self.delegate respondsToSelector:@selector(collectionView:heightForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView heightForFooterInSection:sectionIndex];
    }
    return 0;
}

- (NSEdgeInsets)edgeInsetsForSection:(NSInteger)sectionIndex
{
    if (self.delegate != nil &&
        [self.delegate conformsToProtocol:@protocol(SWCollectionViewHorizontalLayoutDelegate)] &&
        [self.delegate respondsToSelector:@selector(collectionView:edgeInsetsForSection:)]) {
        return [self.delegate collectionView:self.collectionView edgeInsetsForSection:sectionIndex];
    }
    return NSEdgeInsetsZero;
}
@end
