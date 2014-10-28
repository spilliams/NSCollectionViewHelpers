#SWTouchScrollCollectionView

A custom subclass of JNWCollectionView that allows a click-drag gesture to control the scrolling of the collection view (in addition to the normal scroll gestures).

There's some weird workarounds in this one because the hardware I was working with at the time was IR-based and very unreliable compared to a capacative touchscreen.

##Usage

*Disclaimer: The following applies to Xcode 6 and up, and JNW as of 18 August 2014.*

###Storyboard

This one's a little trickier. I start by creating a collection view in the storyboard and setting its class to "SWTouchScrollCollectionView". I set it up as an IBOutlet in my view controller, and wire its data source, delegate, refreshDelegate and scrollDelegate to the same view controller.

Next up we wire a Pan gesture recognizer (GR) to the collection view. For some reason we can't embed the pan GR within the collection view, so we put it in the collection view's superview. Wire the pan GR to a method **in MyViewController.m** (and also wire MyViewController as the delegate to the pan GR). For instance:

    - (BOOL)gestureRecognizerShouldBegin:(NSGestureRecognizer *)gestureRecognizer
    {
        // you could implement some code here to prevent any touch scroll collection view from scrolling
    }
    - (IBOutlet)handlePanGesture:(NSPanGestureRecognizer *)gestureRecognizer
    {
        // In case you have multiple SWTouchScrollCollectionViews showing in the same window, you'll have to write
        // some code here to determine which to send the gesture to. Once you figure that out you can call
        
        [self.myCollectionView handlePanGesture:gestureRecognizer];
    }

I have noticed one bug where if you have one SWTouchScrollCollectionView **on top** of another, scrolling might happen unexpectedly in the wrong collection view. That's why I had to do this workaround of handling the pan gesture in the view controller before passing it to the collection view.

###MyViewController.h

    ...
    #import "SWTouchScrollCollectionView.h"
    
    @interface MyViewController : NSViewController <SWTouchScrollCollectionViewDelegate, SWPullToRefreshDelegate, JNWCollectionViewDataSource, JNWCollectionViewDelegate>
    
    ...
    @property (nonatomic, weak) IBOutlet SWTouchScrollCollectionView *myCollectionView;
        
    @end

###MyViewController.m

I'll go through this one method-by-method, since it's rather long

    #pragma mark - View Lifecycle
    
    - (void)viewDidLoad
    {
        [super viewDidLoad];
        
        ...
        
        // setup collection view
        [self.myCollectionView newPointSmootherWithLength:25];
        [self.myCollectionView setScrollScaling:CGPointMake(1.5, 1.5)];
        [self.myCollectionView setScrollDirection:SWTouchScrollDirectoinVertical];
        
        // set the collection view's layout, if desired
        
        // register cells
        [self.myCollectionView registerNib:[[NSNib alloc] initWithNibNamed:"MyCell" bundle:nil] forCellWithReuseIdentifier:@"MyCell"];
    }

After the view loads (but before it appears), we set up the details of the collection view. This includes adding a point smoother, setting the scroll scaling, giving it a layout and registering its cells.

A point smoother basically gives the collection view a moving average to work with instead of raw touch events. Play around with different lengths. If your touchscreen is very high resolution, you may want a value of 1 here (Or try 0? It might break though. I dunno). I like 25 for my purpose, but keep in mind that for really high numbers, the scrolling may appear very strange. (If you notice bugs in its behavior, file an [Issue](https://github.com/spilliams/SWCollectionViewStaggeredGridLayout/issues)).

The scroll scaling lets you scroll by a factor of the perceived scroll distance. So if the user's finger travels 15 points, and your scaling is 2, then the view will actually scroll 30 points.

    
    #pragma mark - Collection View Protocols
    #pragma mark JNWCollectionViewDataSource Protocol
    
    - (NSUInteger)collectionView:(JNWCollectionView *)collectionView
          numberOfItemsInSection:(NSInteger)section
    {
        return 10;
    }
    - (JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                       cellForItemAtIndexPath:(NSIndexPath *)indexPath
    {
        MyCell *cell = (MyCell *)[collectionView dequeueReusableCellWithIdentifier:@"MyCell"];
        return cell;
    }
    - (JNWCollectionViewReusableView *)collectionView:(JNWCollectionView *)collectionView viewForSupplementaryViewOfKind:(NSString *)kind inSection:(NSInteger)section
    {
        // optional
        return [NSView new];
    }

These are standard data source methods for a JNWCollectionView. They should be documented within that package.

    #pragma mark JNWCollectionViewDelegate Protocol

    - (void)collectionView:(JNWCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
    {
        // handle what happens when a cell is selected
    }

This is a standard delegate method for a JNWCollectionView.

I won't cover my custom layout delegate protocols here, see other parts of this repository for those. You will almost definitely have to implement some kind of layout delegate methods, at least to give the cells their size.

Finally, we come to the SWTouchScroll delegates:

    #pragma mark SWTouchScrollCollectionViewDelegate Protocol
    
    - (void)touchScrollCollectionViewWillStartScrolling:(SWTouchScrollCollectionView *)touchScrollCollectionView
    {
        // here you can choose to respond to the collection view starting to scroll
    }
    
    - (void)touchScrollCollectioniVewDidEndScrolling:(SWTouchScrollCollectionView *)touchScrollCollectionView
    {
        // here you can choose to respond to the collection view ending a scroll
    }
    
    #pragma mark SWPullToRefreshDelegate Protocol
    
    - (void)scrollViewReachedBottom:(UCTouchScrollCollectionView *)scrollView
    {
        // Here you can choose to respond to a collection view reaching its bottom.
    }

I think these implementations are pretty self-explanatory.
