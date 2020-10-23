//
//  VMSMapTypeControl.h
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/13/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VTMBaseControl.h"

typedef enum {
    VMSMapTypeTransport = 0,
    VMSMapTypeAdmin = 1,
    VMSMapTypeTerrain = 2,
    VMSMapTypeSattelite = 3,
} VTMMapType;

@interface VTMMapTypeControl : VTMBaseControl

/**
 * Set map type cho control va map
 */
- (void)setMapType:(VTMMapType)mapType;

@end
