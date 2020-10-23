//
//  VMSMapTypeControl.m
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/13/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "VTMBaseControl_Ext.h"
#import "VTMMapTypeControl.h"
#import <Mapbox/Mapbox.h>

@implementation VTMMapTypeControl {
    @private UIButton *btnMapType;
}

- (id)init {
    return nil;
}

- (id)initWithFrame:(CGRect)frame {
    return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return nil;
}

- (id)initWithMap:(VMSMapView *)map {
    self = [super initWithMap:map];
    if (self) {
        [self createControl];
        [self updateControl];
    }
    return self;
}

- (void)createControl {
    VMSMapType mapType;
    if (self.mapView) {
        mapType = self.mapView.mapType;
    } else {
        // default map type : transportation
        mapType = VMSMapTypeTransport;
    }
    
    NSString *iconName = [NSString stringWithFormat:@"vtmap_ic_btn_layer_%d.png", mapType];
    UIImage *icon = [UIImage imageNamed:iconName];
    
    if(CGRectEqualToRect(self.frame, CGRectZero)) {
        int offsetX = 0;
        if (self.mapView) {
            offsetX = self.mapView.mapWidth - icon.size.width - VMSControlMargin;
        }
//        self.frame = CGRectMake(offsetX, self.mapView.frame.origin.y + VMSControlMargin, icon.size.width, icon.size.height);
        self.frame = CGRectMake(offsetX, VMSControlMargin, icon.size.width, icon.size.height);
    }
    
    btnMapType = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, icon.size.width, icon.size.height)];
    [btnMapType setBackgroundImage:icon forState:UIControlStateNormal];
    btnMapType.layer.masksToBounds = YES;
    btnMapType.layer.cornerRadius = 5.0f;
    btnMapType.layer.borderWidth = 1.0f;
	btnMapType.layer.borderColor = [UIColor grayColor].CGColor;
    
    [btnMapType addTarget:self action:@selector(changeMapLayer:) forControlEvents:UIControlEventTouchUpInside];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin];
    [self addSubview:btnMapType];
    
    if (self.mapView != nil) {
        [self.mapView addSubview:self];
        [self.mapView bringSubviewToFront:self];
    }
}

- (void)updateControl {
    if (self.mapView != nil) {
        [self updateImageIcon:self.mapView.mapType];
    }
}

- (VMSControlType)controlType {
    return VMSTypeControlMapType;
}

- (void)setMapType:(VMSMapType)mapType {
    if (self.mapView) {
        self.mapView.mapType = mapType;
//        [self updateImageIcon:mapType];
    }
}

- (IBAction)changeMapLayer:(id)sender {
    if (self.mapView == nil || btnMapType == nil) {
        // Don't have mapView or button yet, can't change image
        return;
    } else {
        VMSMapType mapType = self.nextMapType;
        self.mapView.mapType = mapType;
        //[self updateImageIcon:mapType];
    }
}

- (VMSMapType)nextMapType {
    if (!self.mapView) {
        return VMSMapTypeTransport;
    }

    VMSMapType mapType = self.mapView.mapType;
    if (VMSMapSRS == VMS_SRS900913) {
        switch (mapType) {
            case VMSMapTypeTransport:
                mapType = VMSMapTypeAdmin;
                break;
            case VMSMapTypeAdmin:
                mapType = VMSMapTypeTerrain;
                break;
            case VMSMapTypeTerrain:
                mapType = VMSMapTypeSattelite;
                break;
            case VMSMapTypeSattelite:
                mapType = VMSMapTypeTransport;
                break;
            default:
                mapType = VMSMapTypeTransport;
                break;
        }
    } else {
        switch (mapType) {
            case VMSMapTypeTransport:
                mapType = VMSMapTypeAdmin;
                break;
            case VMSMapTypeAdmin:
                mapType = VMSMapTypeTransport;
                break;
            default:
                mapType = VMSMapTypeTransport;
                break;
        }
    }
    return mapType;
}

- (void)updateImageIcon:(VMSMapType)mapType {
    NSString *iconName = [NSString stringWithFormat:@"vtmap_ic_btn_layer_%d.png", mapType];
    UIImage *icon = [UIImage imageNamed:iconName];
    [btnMapType setBackgroundImage:icon forState:UIControlStateNormal];
    if (self.mapView) {
        [self.mapView refresh];
    }
}

- (void)setEnabledControl:(BOOL)enabled {
    if (btnMapType) {
        [btnMapType setEnabled:enabled];
    }
}

- (void) dealloc {
    if (btnMapType) {
        [btnMapType removeFromSuperview];
    }

    btnMapType = nil;
    self.mapView = nil;
}

@end
