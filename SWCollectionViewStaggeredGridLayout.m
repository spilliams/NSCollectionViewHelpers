//
//  SWCollectionViewStaggeredGridLayout.m
//  CurrentScience
//
//  Created by Spencer Williams on 9/29/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import "SWCollectionViewStaggeredGridLayout.h"

#define LOG NO
#define LOG_IN_RECT LOG&&NO

// A lot of this implementation is copypasta from JNWCollectionViewGridLayout.m
// but I'm not sure of a better way to structure things without forking JNW and
// writing a shared "JNWCollectionViewGridLayout_Protected.h"

typedef struct {
    CGPoint origin;
    CGSize size;
} JNWCollectionViewGridLayoutItemInfo;

@interface SWCollectionViewStaggeredGridLayoutColumnItemInfo : NSObject
    @property (nonatomic, assign) NSIndexPath *indexPath;
    @property (nonatomic, assign) CGPoint origin;
    @property (nonatomic, assign) CGSize size;
@end

@implementation SWCollectionViewStaggeredGridLayoutColumnItemInfo
@end

// identical to that in JNWCollectionViewGridLayout with the following exceptions:
// `columns` property contains column data ("which index paths are in each column")
@interface JNWCollectionViewGridLayoutSection : NSObject
- (instancetype)initWithNumberOfItems:(NSInteger)numberOfItems;
@property (nonatomic, assign) CGFloat offset;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger numberOfItems;
/// A pointer to the first item in a C array of itemInfo structs
@property (nonatomic, assign) JNWCollectionViewGridLayoutItemInfo *itemInfo;

@property (nonatomic, strong) NSArray *columns;
@end

@implementation JNWCollectionViewGridLayoutSection

- (instancetype)initWithNumberOfItems:(NSInteger)numberOfItems {
    self = [super init];
    if (self == nil) return nil;
    
    _numberOfItems = numberOfItems;
    self.itemInfo = calloc(numberOfItems, sizeof(JNWCollectionViewGridLayoutItemInfo));
    return self;
}

- (void)dealloc {
    // inherited from JNWCollectionViewGridLayout, but I don't actually
    // know much about this. I think this is because itemInfo is a C array?
    if (_itemInfo != NULL)
        free(_itemInfo);
}

@end

@interface SWCollectionViewStaggeredGridLayout()
@property (nonatomic, strong) NSMutableArray *sections;
@end

@implementation SWCollectionViewStaggeredGridLayout

- (NSMutableArray *)sections {
    if (_sections == nil) {
        _sections = [NSMutableArray array];
    }
    return _sections;
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
    if (LOG) NSLog(@"  verticalSpacing %f", self.verticalSpacing);
    CGFloat totalWidth = self.collectionView.visibleSize.width;
    
    // Layout each section at a time.
    CGFloat totalHeight = 0;
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        if (LOG) NSLog(@"  section %lu", (unsigned long)section);
        
        // number of columns, item width
        NSInteger numberOfColumns = [self.staggeredDelegate numberOfColumnsInCollectionView:self.collectionView section:section];
        NSAssert(numberOfColumns > 0, @"Staggered delegate must return a positive, non-zero number of columns");
        NSEdgeInsets sectionInsets = [self edgeInsetsForSection:section];
        if (LOG) NSLog(@"    sectionInsets {top: %f, left: %f, bottom: %f, right: %f}",
                       sectionInsets.top,
                       sectionInsets.left,
                       sectionInsets.bottom,
                       sectionInsets.right);
        CGFloat columnsWidth = totalWidth - sectionInsets.left - sectionInsets.right;
        CGFloat itemWidth = (columnsWidth / numberOfColumns) - self.itemHorizontalMargin;
        if (LOG) NSLog(@"    item width %f", itemWidth);
        
        // set up column data object
        NSMutableArray *columnData = [NSMutableArray arrayWithCapacity:numberOfColumns];
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        if (LOG) NSLog(@"    numberOfItems %li", (long)numberOfItems);
        for (NSInteger c = 0; c < numberOfColumns; c++) {
            // worst case (1 column), we're putting all items into each column
            [columnData addObject:[NSMutableArray arrayWithCapacity:numberOfItems]];
        }
        
        // determine section-related dimensions
        NSInteger headerHeight = [self headerHeightForSection:section];
        if (LOG) NSLog(@"    headerHeight %li", (long)headerHeight);
        NSInteger footerHeight = [self footerHeightForSection:section];
        if (LOG) NSLog(@"    footerHeight %li", (long)footerHeight);
        
        // set up section info object
        JNWCollectionViewGridLayoutSection *sectionInfo = [[JNWCollectionViewGridLayoutSection alloc] initWithNumberOfItems:numberOfItems];
        sectionInfo.offset = totalHeight + headerHeight + sectionInsets.top;
        sectionInfo.height = 0;
        sectionInfo.index = section;
        sectionInfo.headerHeight = headerHeight;
        sectionInfo.footerHeight = footerHeight;
        
        // for putting each item into the shortest column
        NSMutableArray *columnHeights = [NSMutableArray arrayWithCapacity:numberOfColumns];
        for (NSInteger column = 0; column < numberOfColumns; column++) {
            [columnHeights addObject:[NSNumber numberWithFloat:0]];
        }
        
        // layout each item individually
        for (NSUInteger item = 0; item < numberOfItems; item++) {
            BOOL logItems = YES;
            if (LOG && logItems) NSLog(@"    item %lu", (unsigned long)item);
            
            CGFloat itemHeight = [self.staggeredDelegate collectionView:self.collectionView
                                                     heightForCellWidth:itemWidth
                                                            atIndexPath:[NSIndexPath jnw_indexPathForItem:item inSection:section]];
            
            CGPoint origin = CGPointZero;
            
            // pick the first column that has the shortest column height in the array
            NSUInteger shortestColumnIndex = 0;
            CGFloat shortestColumnHeight = [[columnHeights objectAtIndex:shortestColumnIndex] floatValue];
            for (NSUInteger column = 1; column < columnHeights.count; column++) {
                CGFloat columnHeight = [[columnHeights objectAtIndex:column] floatValue];
                if (columnHeight < shortestColumnHeight) {
                    shortestColumnHeight = columnHeight;
                    shortestColumnIndex = column;
                }
            }
            NSString *columnHeightsString = @"{";
            for (int temp = 0; temp < numberOfColumns; temp++) {
                if (temp != 0) columnHeightsString = [columnHeightsString stringByAppendingString:@", "];
                columnHeightsString = [columnHeightsString stringByAppendingString:[[columnHeights objectAtIndex:temp] stringValue]];
            }
            columnHeightsString = [columnHeightsString stringByAppendingString:@"}"];
            if (LOG && logItems) NSLog(@"      picked column %i (%i tall). %@", (int)shortestColumnIndex, (int)shortestColumnHeight, columnHeightsString);
            
            // set the item's origin
            origin.x = sectionInsets.left + self.itemHorizontalMargin * 0.5 + shortestColumnIndex * (itemWidth + self.itemHorizontalMargin);
            origin.y = shortestColumnHeight;
            sectionInfo.itemInfo[item].origin = origin;
            sectionInfo.itemInfo[item].size = CGSizeMake(itemWidth, itemHeight);
            
            // setup the column item info object
            SWCollectionViewStaggeredGridLayoutColumnItemInfo *columnItemInfo = [SWCollectionViewStaggeredGridLayoutColumnItemInfo new];
            columnItemInfo.origin = origin;
            columnItemInfo.indexPath = [NSIndexPath jnw_indexPathForItem:item inSection:section];
            columnItemInfo.size = CGSizeMake(itemWidth, itemHeight);
            
            if (LOG && logItems) NSLog(@"      item origin: %@", NSStringFromPoint(columnItemInfo.origin));
            if (LOG && logItems) NSLog(@"      item size: %@", NSStringFromSize(columnItemInfo.size));
            
            // update column heights
            [columnHeights replaceObjectAtIndex:shortestColumnIndex withObject:[NSNumber numberWithFloat:columnItemInfo.origin.y + columnItemInfo.size.height + self.verticalSpacing]];
            
            // add column item info to column data object
            [[columnData objectAtIndex:shortestColumnIndex] addObject:columnItemInfo];
            
        } // item loop
        
        // determine tallest column (for section height)
        CGFloat tallestColumnHeight = [[columnHeights objectAtIndex:0] floatValue];
        for (NSInteger column = 0; column < columnHeights.count; column++) {
            tallestColumnHeight = MAX([[columnHeights objectAtIndex:column] floatValue], tallestColumnHeight);
        }
        sectionInfo.height = tallestColumnHeight;
        if (LOG) NSLog(@"    section height: %f",tallestColumnHeight);
        totalHeight += sectionInfo.height + footerHeight + headerHeight + sectionInsets.top + sectionInsets.bottom;
        [self.sections addObject:sectionInfo];
        sectionInfo.columns = columnData;
        
    } // section loop
    
    if (LOG) NSLog(@"done preparing layout for %i sections", (int)self.sections.count);
}

- (JNWCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    JNWCollectionViewGridLayoutSection *section = self.sections[indexPath.jnw_section];
    JNWCollectionViewGridLayoutItemInfo itemInfo = section.itemInfo[indexPath.jnw_item];
    CGFloat offset = section.offset;
    
    JNWCollectionViewLayoutAttributes *attributes = [[JNWCollectionViewLayoutAttributes alloc] init];
    attributes.frame = CGRectMake(itemInfo.origin.x, itemInfo.origin.y + offset, itemInfo.size.width, itemInfo.size.height);
    attributes.alpha = 1.f;
    return attributes;
}

- (NSArray *)indexPathsForItemsInRect:(CGRect)rect
{
    if (LOG_IN_RECT) NSLog(@"[layout] indexPathsForItemsInRect: {%f, %f, %f, %f}", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    for (NSUInteger section = 0; section < self.sections.count; section++) {
        
        // first check if section is in rect
        if (!CGRectIntersectsRect([self rectForSectionAtIndex:section], rect)) continue;
        if (LOG_IN_RECT) NSLog(@"  section %i is in rect", (int)section);
        JNWCollectionViewGridLayoutSection *sectionInfo = [self.sections objectAtIndex:section];
        
        
        // then determine which columns are in the rect
        NSInteger numberOfColumns = [self.staggeredDelegate numberOfColumnsInCollectionView:self.collectionView section:section];
        CGFloat columnWidth = self.collectionView.visibleSize.width / numberOfColumns;
        NSRange columnsInRect = NSMakeRange(0, 0);
        CGPoint testPoint = CGPointMake(0, CGRectGetMinY(rect));
        for (NSInteger column = 0; column < numberOfColumns; column++) {
            if (CGRectContainsPoint(rect, testPoint)) {
                if (columnsInRect.length == 0) {
                    columnsInRect = NSMakeRange(column, 1);
                } else {
                    columnsInRect.length++;
                }
            }
            
            testPoint.x += columnWidth;
        }
        
        // finally get which items
        for (NSUInteger columnIndex = columnsInRect.location; columnIndex < columnsInRect.length; columnIndex++) {
            NSArray *column = [sectionInfo.columns objectAtIndex:columnIndex];
            
            for (NSUInteger item = 0; item < column.count; item++) {
                SWCollectionViewStaggeredGridLayoutColumnItemInfo *itemInfo = [column objectAtIndex:item];
                
                // FIXME: play with various edge insets, header and footer heights.
                // I'm not sure this algebra holds up.
                // item origin already includes edge insets, but I'm not sure we need
                // to add collection view frame origin?
                CGRect itemRect = CGRectMake(itemInfo.origin.x + self.collectionView.frame.origin.x,
                                             itemInfo.origin.y + sectionInfo.offset + self.collectionView.frame.origin.y,
                                             itemInfo.size.width,
                                             itemInfo.size.height);
                if (CGRectIntersectsRect(itemRect, rect)) {
                    if (LOG_IN_RECT) NSLog(@"    item %i is in rect", (int)itemInfo.indexPath.jnw_item);
                    [indexPaths addObject:itemInfo.indexPath];
                }
            } // item loop
        } // column loop
    } // section loop
    return indexPaths;
}

- (NSIndexPath *)indexPathForNextItemInDirection:(JNWCollectionViewDirection)direction currentIndexPath:(NSIndexPath *)currentIndexPath
{
    // determine which column the item is in
    NSInteger section = currentIndexPath.jnw_section;
    JNWCollectionViewGridLayoutSection *sectionInfo = [self.sections objectAtIndex:section];
    NSInteger numberOfColumns = [self.staggeredDelegate numberOfColumnsInCollectionView:self.collectionView section:section];
    
    for (NSUInteger columnIndex = 0; columnIndex < numberOfColumns; columnIndex++) {
        
        NSArray *column = [sectionInfo.columns objectAtIndex:columnIndex];
        for (NSUInteger item = 0; item < column.count; item++) {
            SWCollectionViewStaggeredGridLayoutColumnItemInfo *itemInfo = [column objectAtIndex:item];
            if (itemInfo.indexPath.jnw_item == currentIndexPath.jnw_item) {
                
                // The cases where the "next item" would be off the board entirely
                if (direction == JNWCollectionViewDirectionLeft && columnIndex == 0) return currentIndexPath;
                if (direction == JNWCollectionViewDirectionRight && columnIndex == numberOfColumns-1) return currentIndexPath;
                if (direction == JNWCollectionViewDirectionUp && item == 0 && section == 0) return currentIndexPath;
                if (direction == JNWCollectionViewDirectionDown && item == column.count-1 && section == self.sections.count-1) return currentIndexPath;
                
                // The cases where the "next item" is in a different section of the data
                if (direction == JNWCollectionViewDirectionUp && item == 0) {
                    JNWCollectionViewGridLayoutSection *nextSectionInfo = [self.sections objectAtIndex:section-1];
                    SWCollectionViewStaggeredGridLayoutColumnItemInfo *nextItemInfo = [[nextSectionInfo.columns objectAtIndex:columnIndex] lastObject];
                    return nextItemInfo.indexPath;
                }
                if (direction == JNWCollectionViewDirectionDown && item == column.count-1) {
                    JNWCollectionViewGridLayoutSection *nextSectionInfo = [self.sections objectAtIndex:section+1];
                    SWCollectionViewStaggeredGridLayoutColumnItemInfo *nextItemInfo = [[nextSectionInfo.columns objectAtIndex:columnIndex] firstObject];
                    return nextItemInfo.indexPath;
                }
                
                // The cases where the "next item" is within the same section
                if (direction == JNWCollectionViewDirectionUp) {
                    return ((SWCollectionViewStaggeredGridLayoutColumnItemInfo *)[column objectAtIndex:item-1]).indexPath;
                }
                if (direction == JNWCollectionViewDirectionDown) {
                    return ((SWCollectionViewStaggeredGridLayoutColumnItemInfo *)[column objectAtIndex:item+1]).indexPath;
                }
                // ok now we get to the harder cases: left and right within the section.
                // There are a few things we know about this grid from the rest of this layout implementation:
                // - The items do not necessarily line up
                // - The grid is minimally sparse (for a lax def. of minimal). This means that there is almost definitely another item very close by. Exception is if this is the last item in the column, and this column (by some trick of the Gods) ended up much longer than those adjacent. In that case we can get close enough by just selecting the last item in the next column
                NSArray *nextColumn = [sectionInfo.columns objectAtIndex:(direction == JNWCollectionViewDirectionLeft ? columnIndex-1 : columnIndex+1)];
                CGFloat adjacency = 0;
                SWCollectionViewStaggeredGridLayoutColumnItemInfo *nextItemInfo;
                for (NSUInteger nextItemIndex = 0; nextItemIndex < nextColumn.count; nextItemIndex++) {
                    SWCollectionViewStaggeredGridLayoutColumnItemInfo *tempItemInfo = [nextColumn objectAtIndex:nextItemIndex];
                    
                    // TODO: not sure why I didn't just save the frame in item info...
                    CGFloat tempAdjacency = [self adjacencyFromRect:NSMakeRect(itemInfo.origin.x,
                                                                               itemInfo.origin.y,
                                                                               itemInfo.size.width,
                                                                               itemInfo.size.height)
                                                             toRect:NSMakeRect(tempItemInfo.origin.x,
                                                                               tempItemInfo.origin.y,
                                                                               tempItemInfo.size.width,
                                                                               tempItemInfo.size.height)];
                    if (tempAdjacency > adjacency) {
                        nextItemInfo = tempItemInfo;
                        adjacency = tempAdjacency;
                    }
                }
                return nextItemInfo.indexPath;
                
            }
            
        } // item loop
        
    } // column loop
    return nil;
}

#pragma mark - Helper Methods

// returns a number representing the length of the shared distance of two rectangles' edges
// only considers y, so the rects could be miles apart on the x axis, or even overlapping.
- (CGFloat)adjacencyFromRect:(NSRect)rect1 toRect:(NSRect)rect2
{
    // rect 1 is below rect 2 entirely
    if (rect1.origin.y >= rect2.origin.y + rect2.size.height) return 0;
    // rect 2 is below rect 1 entirely
    if (rect2.origin.y >= rect1.origin.y + rect1.size.height) return 0;
    
    // rect 1 is above rect 2 a little
    if (rect1.origin.y < rect2.origin.y) return rect1.size.height - (rect2.origin.y - rect1.origin.y);
    else return rect2.size.height - (rect1.origin.y - rect2.origin.y);
    
    /*
     Different mode, just for fun:
     this one returns the distance between the two rects' centers.
     
     return sqrt(abs(rect1.origin.x - rect2.origin.x) ^ 2 + abs(rect1.origin.y - rect2.origin.y) ^ 2);
     */
    
}

- (CGFloat)headerHeightForSection:(NSInteger)section
{
    BOOL delegateHeightForHeader = [self.delegate respondsToSelector:@selector(collectionView:heightForHeaderInSection:)];
    CGFloat headerHeight = delegateHeightForHeader ? [self.delegate collectionView:self.collectionView heightForHeaderInSection:section] : 0;
    return headerHeight;
}

- (CGFloat)footerHeightForSection:(NSInteger)section
{
    BOOL delegateHeightForFooter = [self.delegate respondsToSelector:@selector(collectionView:heightForFooterInSection:)];
    CGFloat footerHeight = delegateHeightForFooter ? [self.delegate collectionView:self.collectionView heightForFooterInSection:section] : 0;
    return footerHeight;
}

- (NSEdgeInsets)edgeInsetsForSection:(NSInteger)section
{
    BOOL delegateForSectionInsets = [self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)];
    NSEdgeInsets sectionInsets = delegateForSectionInsets ? [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section] : NSEdgeInsetsMake(0, 0, 0, 0);
    return sectionInsets;
}

@end
