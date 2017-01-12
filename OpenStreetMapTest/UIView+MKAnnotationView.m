//
//  UIView+MKAnnotationView.m
//  OpenStreetMapTest
//
//  Created by Kanat on 10/01/2017.
//  Copyright © 2017 ak. All rights reserved.
//

#import "UIView+MKAnnotationView.h"

@implementation UIView (MKAnnotationView)

- (MKAnnotationView*)superAnnotationView {
    if ([self isKindOfClass:[MKAnnotationView class]]) {
        return (MKAnnotationView*)self;
    }
    if (!self.superview) {
        return nil;
    }
    return [self.superview superAnnotationView];
}

@end
