//
//  VMSBaseControl.m
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/13/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VTMBaseControl_Ext.h"
//#import "VMSMapView.h"
#import <Mapbox/Mapbox.h>
@implementation VTMBaseControl

@synthesize mapView = _mapView;

- (id)init {
    return nil;
}

- (id)initWithFrame:(CGRect)frame {
    return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return nil;
}

- (id)initWithMap:(MGLMapView *)map {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        marginTop = VMSControlMargin;
        marginBottom = VMSControlMargin;
        marginLeft = VMSControlMargin;
        marginRight = VMSControlMargin;
        
        horizontalAlign = VMSAlignNone;
        verticalAlign = VMSAlignNone;

        self.mapView = map;
        
        //[self createControl];
        //[self updateControl];
    }
    return self;
}

- (void)createControl {
    return;
}

- (void)updateControl {
    return;
}

- (VMSControlType)controlType {
    return VMSTypeControlBase;
}

- (void)setEnabledControl:(BOOL)enabled {
    return;
}

- (void)setMarginTop:(int)top bottom:(int)bottom left:(int)left right:(int)right {
    marginTop = top;
    marginBottom = bottom;
    marginLeft = left;
    marginRight = right;
    [self updateView];
}

- (id)alignTop {
    verticalAlign = VMSAlignTop;
    [self updateView];
    return self;
}

- (id)alignBottom {
    verticalAlign = VMSAlignBottom;
    [self updateView];
    return self;
}

- (id)alignMiddle {
    verticalAlign = VMSAlignMiddle;
    [self updateView];
    return self;
}

- (id)alignLeft {
    horizontalAlign = VMSAlignLeft;
    [self updateView];
    return self;
}

- (id)alignRight {
    horizontalAlign = VMSAlignRight;
    [self updateView];
    return self;
}

- (id)alignCenter {
    horizontalAlign = VMSAlignCenter;
    [self updateView];
    return self;
}

- (void)updateView {
    CGRect rect = self.frame;
    
    if (verticalAlign == VMSAlignTop) {
        rect.origin.y = marginTop;
    } else if (verticalAlign == VMSAlignBottom) {
        rect.origin.y = _mapView.frame.size.height - rect.size.height - marginBottom;
        
    } else if (verticalAlign == VMSAlignMiddle) {
        rect.origin.y = (_mapView.frame.size.height - rect.size.height) / 2;
    }

    if (horizontalAlign == VMSAlignLeft) {
        rect.origin.x = marginLeft;
    } else if (horizontalAlign == VMSAlignRight) {
        rect.origin.x = _mapView.frame.size.width - rect.size.width - marginRight;
    } else if (horizontalAlign == VMSAlignCenter) {
        rect.origin.x = (_mapView.frame.size.width - rect.size.width) / 2;
    }
    
    self.frame = rect;
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame {
    horizontalAlign = VMSAlignNone;
    verticalAlign = VMSAlignNone;
    [super setFrame:frame];
}

@end
