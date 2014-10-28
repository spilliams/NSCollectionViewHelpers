#SWCollectionViewHorizontalLayout

Still a work in progress. A horizontally-scrolling collection (or rather, each section's content scrolls horzontally). Section headers and footers go above and below the content, as before, and don't scroll.

##Usage

Much like any other layout, import the .h file and set your JNWCollectionView's layout to an instance of SWCollectionViewHorizontal Layout

###SWCollectionViewHorizontalLayoutDelegate

The delegate for this layout has a method for sizing an item at a particular index path, as well as optional methods for determining section header, footer and edge insets.
