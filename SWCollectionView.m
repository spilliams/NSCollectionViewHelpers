//
//  SWCollectionView.m
//  CurrentScience
//
//  Created by Spencer Williams on 12/1/14.
//  Copyright (c) 2014 Uncorked Studios. All rights reserved.
//

#import "SWCollectionView.h"
#import "SWCollectionViewDocumentView.h"

@interface SWCollectionView () {
    BOOL documentViewSet;
}

@end

@implementation SWCollectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (!documentViewSet) {
        // Set the background properly
            NSColor *backgroundColor = ((NSScrollView *)self).backgroundColor;
        if (self.sw_delegate != nil && [self.sw_delegate respondsToSelector:@selector(backgroundColorForCollectionView:)]) {
            backgroundColor = [self.sw_delegate backgroundColorForCollectionView:self];
            [self setDrawsBackground:NO];
        }
        self.documentView = [[SWCollectionViewDocumentView alloc] initWithFrame:CGRectZero backgroundColor:backgroundColor];
        documentViewSet = YES;
    }
}

@end
