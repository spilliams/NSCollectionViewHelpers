//
//  SWCollectionViewDocumentView.m
//  CurrentScience
//
//  Created by Spencer Williams on 10/28/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import "SWCollectionViewDocumentView.h"

@interface SWCollectionViewDocumentView ()
@property (nonatomic, strong) NSColor *backgroundColor;
@end

@implementation SWCollectionViewDocumentView

- (instancetype)initWithFrame:(NSRect)frameRect backgroundColor:(NSColor *)backgroundColor
{
    if (self = [self initWithFrame:frameRect]) {
        self.backgroundColor = backgroundColor;
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    [super drawRect:dirtyRect];
}

@end
