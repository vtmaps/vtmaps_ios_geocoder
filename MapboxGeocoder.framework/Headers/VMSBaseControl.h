//
//  VMSBaseControl.h
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/13/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MGLMapView;

/**
 * Dinh nghia cac kieu control
 */
typedef enum {
    VMSTypeControlBase      =  -1,
    VMSTypeControlZoom      =   1,
    VMSTypeControlMapType   =   2,
    VMSTypeControlGPS       =   3,
    VMSTypeControlScale     =   4,
    VMSTypeControlGPSNew       =   5,
} VMSControlType;

@interface VMSBaseControl : UIView

@property (nonatomic, weak) MGLMapView *mapView;
@property (nonatomic, readonly) VMSControlType controlType;

/**
 * Ham khoi tao su dung vi tri mac dinh
 */
- (id)initWithMap:(MGLMapView *)map;

///**
// * Update lai control theo cac thuoc tinh da set truoc do
// */
//- (void)updateControl;

/**
 * Bat / tat control
 */
- (void)setEnabledControl:(BOOL)enabled;

/**
 * Cac ham set alignment cua control
 */
- (id)alignTop;
- (id)alignBottom;
- (id)alignMiddle;
- (id)alignLeft;
- (id)alignRight;
- (id)alignCenter;

/**
 * Set margin for control
 */
- (void)setMarginTop:(int)top bottom:(int)bottom left:(int)left right:(int)right;

/**
 * Set frame custom position
 */
- (void)setFrame:(CGRect)frame;

/**
 * Khong su dung cac ham init mac dinh
 */
- (id)init __attribute__((unavailable("use initWithMap instead of this")));
- (id)initWithCoder:(NSCoder *)aDecoder __attribute__((unavailable("use initWithMap instead of this")));
- (id)initWithFrame:(CGRect)frame __attribute__((unavailable("use initWithMap instead of this")));

@end
