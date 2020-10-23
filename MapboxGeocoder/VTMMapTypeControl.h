//
//  VMSMapTypeControl.h
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/13/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VTMBaseControl.h"

typedef enum {
    VTMMapTypeTransport = 0,// giao thong
    VTMMapTypeAdmin = 1,//hanh chinh
    VTMMapTypeTerrain = 2, //google
    VTMMapTypeSattelite = 3,// ve tinh
} VTMMapType;

/**
 * Delegate lắng nghe các sự kiện của GPSControl
 */
@protocol VTMMapStyleDelegate <NSObject>
@required
- (void)changedMapStyleSuccess:(VTMMapType )vtmapStyle;
- (void)changedMapStyleError;
@end


int const VMS_SRS900913 = 900913;
int VMSMapSRS = VMS_SRS900913;


@interface VTMMapTypeControl : VTMBaseControl

@property (nonatomic, weak) id<VTMMapStyleDelegate> delegate;

- (id)initWithMap:(MGLMapView *)map delegate:(id<VTMMapStyleDelegate>) delegate;

/**
 * Set map type cho control va map
 */
- (void)setMapType:(VTMMapType)mapType;

- (void)enabledMapTypeTerrain:(BOOL)enabled;
- (void)enabledMapTypeSattelite:(BOOL)enabled;
- (BOOL)isMapTypeTerrainEnable;
- (BOOL)isMapTypeSatteliteEnable;

@end
