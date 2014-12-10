#NSCollectionView Helpers

Being a collection of helper classes for NSCollectionView. Note that this applies to **Mac** applications, **not iOS**.

##JNW Layouts

These layouts are for use with [JNWCollectionView](https://github.com/jwilling/JNWCollectionView).

- SWCollectionViewStaggeredGridLayout: mimics a Pinterest-style staggered grid
- SWCollectionViewHorizontalLayout: a collection view that scrolls horizontally.

##Other Helpers

- SWTouchScrollCollectionView: for when you want a click-drag to scroll your collection view as well as the normal scroll methods. There's some weird workarounds in this one because the tablet hardware I was using at the time was very unreliable. Usage is currently very janky, it requires external pan GRs (in case the view controller contains multiple CVs, and a pan gesture that starts in one and ends in another needs to still scroll the former)
