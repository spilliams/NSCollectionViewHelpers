//
//  SWCollectionViewDocumentView.h
//  CurrentScience
//
//  Created by Spencer Williams on 10/28/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/// A document view to replace JNWCollectionViewDocumentView (adds support for background color in Yosemite)
@interface SWCollectionViewDocumentView : NSView
/// The document view's background color
@property (nonatomic, strong) NSColor *backgroundColor;
/// Initializes a new document view with a specified background color
/// @param  frameRect   The view's frame
/// @param  backgroundColor The view's background color
- (instancetype)initWithFrame:(NSRect)frameRect backgroundColor:(NSColor *)backgroundColor;
@end
