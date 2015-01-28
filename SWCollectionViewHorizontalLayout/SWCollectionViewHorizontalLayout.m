//
//  SWCollectionViewHorizontalLayout.m
//
//  Created by Spencer Williams on 10/16/14.
//  This is free and unencumbered software released into the public domain.
//

#import "SWCollectionViewHorizontalLayout.h"

#define LOG NO

typedef struct {
    /// Origin WRT section start (not including header or footer)
    CGPoint origin;
    CGSize size;
} SWCollectionViewHorizontalLayoutItemInfo;

typedef NS_ENUM(NSInteger, SWSectionEdge) {
    SWSectionEdgeLeft,
    SWSectionEdgeRight
};

// Each section is a row
// header is a width before the first item
// footer is a width after the last item
// a section has a height, which is determined from the tallest item in the section
// offset is a y value of how far this section is offset from the beginning of the layout
@interface SWCollectionViewHorizontalLayoutSection : NSObject
@property (nonatomic, assign) CGFloat offset;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat headerWidth;
@property (nonatomic, assign) CGFloat footerWidth;
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
        NSLog(@" ");
        NSLog(@" ");
        NSLog(@" ");
        NSLog(@" ");
        NSLog(@" ");
        NSLog(@" ");
        NSLog(@" ");
        NSLog(@"vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
        NSLog(@"[layout] preparing layout...");
    }
    [self.sections removeAllObjects];
    
    // values for the entire layout
    NSUInteger numberOfSections = [self.collectionView numberOfSections];
    if (LOG) NSLog(@"  numberOfSections %lu", (unsigned long)numberOfSections);
    if (LOG) NSLog(@"  horizontal margin %f", self.itemHorizontalMargin);
    
    // Each section is on its own row
    CGFloat totalHeight = 0;
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        if (LOG) NSLog(@"  section %i", (int)section);
        
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        
        NSEdgeInsets sectionInsets = [self edgeInsetsForSection:section];
        if (LOG) NSLog(@"    sectionInsets {top: %f, left: %f, bottom: %f, right: %f}",
                       sectionInsets.top,
                       sectionInsets.left,
                       sectionInsets.bottom,
                       sectionInsets.right);
        
        NSInteger headerWidth = [self headerWidthForSection:section];
        if (LOG) NSLog(@"    headerWidth %li", (long)headerWidth);
        NSInteger footerWidth = [self footerWidthForSection:section];
        if (LOG) NSLog(@"    footerWidth %li", (long)footerWidth);
        
        SWCollectionViewHorizontalLayoutSection *sectionInfo = [[SWCollectionViewHorizontalLayoutSection alloc] initWithNumberOfItems:numberOfItems];
        sectionInfo.offset = totalHeight + sectionInsets.top;
        sectionInfo.headerWidth = headerWidth;
        sectionInfo.footerWidth = footerWidth;
        sectionInfo.index = section;
        
        CGFloat maxItemHeight = 0;
        
        for (NSInteger item = 0; item < numberOfItems; item++) {
            if (LOG) NSLog(@"      item %i", (int)item);
            NSIndexPath *indexPath = [NSIndexPath jnw_indexPathForItem:item inSection:section];
            CGSize size = [self.delegate collectionView:self.collectionView sizeForItemAtIndexPath:indexPath];
            CGPoint origin = CGPointMake(sectionInsets.left + item * (self.itemHorizontalMargin + size.width), sectionInsets.top);
            maxItemHeight = MAX(maxItemHeight, size.height);
            if (LOG) NSLog(@"        origin %@", NSStringFromPoint(origin));
            if (LOG) NSLog(@"        size %@", NSStringFromSize(size));
            if (LOG) NSLog(@"        (frame) %@", NSStringFromRect(NSMakeRect(origin.x, origin.y, origin.x+size.width, origin.y+size.height)));
            sectionInfo.itemInfo[item].size = size;
            sectionInfo.itemInfo[item].origin = origin;
        } // item loop
        
        sectionInfo.height = maxItemHeight + sectionInsets.top + sectionInsets.bottom;
        totalHeight += sectionInfo.height;
        [self.sections addObject:sectionInfo];
        
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
    SWCollectionViewHorizontalLayoutSection *sectionInfo = self.sections[sectionIndex];
    CGFloat height = sectionInfo.height;
    CGRect frame = CGRectZero;
    
    if ([kind isEqualToString:JNWCollectionViewGridLayoutHeaderKind]) {
        frame = CGRectMake(0, sectionInfo.offset, sectionInfo.headerWidth, height);
    } else if ([kind isEqualToString:JNWCollectionViewGridLayoutFooterKind]) {
        frame = CGRectMake(0, sectionInfo.offset + sectionInfo.height, sectionInfo.footerWidth, height);
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

- (CGFloat)headerWidthForSection:(NSInteger)sectionIndex
{
    if (self.delegate != nil &&
        [self.delegate conformsToProtocol:@protocol(SWCollectionViewHorizontalLayoutDelegate)] &&
        [self.delegate respondsToSelector:@selector(collectionView:widthForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView widthForHeaderInSection:sectionIndex];
    }
    return 0;
}

- (CGFloat)footerWidthForSection:(NSInteger)sectionIndex
{
    if (self.delegate != nil &&
        [self.delegate conformsToProtocol:@protocol(SWCollectionViewHorizontalLayoutDelegate)] &&
        [self.delegate respondsToSelector:@selector(collectionView:widthForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView widthForFooterInSection:sectionIndex];
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
