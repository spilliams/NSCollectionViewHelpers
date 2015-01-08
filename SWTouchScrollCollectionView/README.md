#TouchScrollView

A custom subclass of NSScrollView that allows a click-drag gesture to control the scrolling of the view (in addition to the normal scroll gestures).

There's some weird workarounds in this one because the hardware I was working with at the time was IR-based and very unreliable compared to a capacative touchscreen. Where applicable I tried to leave ways to shortcut these workarounds so that applications with better hardware wouldn't need to waste the processor time.

##Usage

*Disclaimer: The following applies to Xcode 6 and up, and JNW as of 7 Jan 2015.*

This feature may be used with collection views, web views and normal scroll views. Check out the usage for any particular case, then below that there are some common usage notes.

###As a Collection View

1. in your storyboard, make a collection view according to the instructions for JNWCollectionView.
2. set its class to be SWTouchScrollCollectionView

###As a Web View

1. in your storyboard, set up a new web view, and set its class to SWTouchScrollWebView

###As a Scroll View

This is currently a little broken, I'll get around to fixing it soon.

###Commonalities

Since the hardware I was working with for my particular application was notably faulty, I had to implement a couple of features that you may choose to use as well:

**Scroll Delegate** allows your view controller to respond to scroll event messages like "will start scrolling", "did end scrolling" and "view reached bottom".

**Point Smoothing** uses a moving average to "smooth" the touch events. This was necessary because the hardware was spotty and the cursor would jump around a little. Adding this is as simple as calling `[myTouchScrollView newPointSmootherWithLength:20]`.

**Scroll Scaling** allows you to change how much the scroll view responds to a touch. Maybe you want it to scroll very quickly or slowly.

**Scroll Direction** is a bitmask, allowing scroll directions in horizontal, vertical, both or none.
