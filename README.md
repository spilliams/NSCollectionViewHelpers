#SWCollectionViewStaggeredGridLayout

![](https://raw.githubusercontent.com/spilliams/SWCollectionViewStaggeredGridLayout/master/screenshot.png)

A collection view layout for [JNWCollectionView](https://github.com/jwilling/JNWCollectionView) that mimics a Pinterest-style staggered grid. Note: **this is for Mac applications, not iOS**.

##Usage

MyViewController.h:

    ...
    #import "SWCollectionViewStaggeredGridLayout.h"
    
    @interface MyViewController : NSViewController <[protocols here. more on this below]>
    @property (nonatomic, weak) IBOutlet UCTouchScrollCollectionView *collectionView
    ...

MyViewController.m:

    ...
    - (void)viewDidLoad
    {
        [super viewDidLoad];
        
        SWCollectionViewStaggeredGridLayout *layout = [SWCollectionViewStaggeredGridLayout new];
        layout.staggeredDelegate = self;
        layout.delegate = self; // JNWCollectionViewGridLayoutDelegate
        // set up layout constants here, like verticalSpacing or itemHorizontalMargin
        
        self.collectionView.collectionViewLayout = layout;
        
        ...
    }

Unlike `JNWCollectionViewGridLayout` (which this class inherits from), the staggered grid layout does not make use of properties `itemSize` or `itemPaddingEnabled`. It also defines its own delegate protocol for calculating item sizes.

###Working with `SWCollectionViewStaggeredGridLayoutDelegate`

Set your view controller to be the layout's `staggeredDelegate` and you can respond to messages `-numberOfColumnsInCollectionView:section:` and `-collectionView:heightForCellWidth:atIndexPath:`. These two methods help the layout in determining item size.

You'll note that one of the parameters to the number of columns method is `section`. This allows you to have different numbers of columns for different sections of your collection view.

###Working with JNW Layout Protocols

You can also set your collection view's `delegate` property to be your view controller. This allows the view controller to respond to methods like `-collectionView:heightForHeaderInSection:`, `-collectionView:heightForFooterInSection:` and `-collectionView:layout:insetForSectionAtIndex:`.

Note that since `SWCollectionViewStaggeredGridLayout` has a complete override of the `-prepareLayout` method, the method `-sizeForItemInCollectionView:` in `JNWCollectionViewGridLayoutDelegate` is completely unused.

##Issues

If you notice problems or discrepancies in the staggered grid layout, please file an issue here. (or fork this repo, commit the fix and send me a pull request!)
