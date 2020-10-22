//
//  VMSBaseControl_Ext.h
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/20/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VTMBaseControl.h"

@class MGLMapView;

typedef enum {
    VMSAlignNone = 0,
    VMSAlignTop = 1,
    VMSAlignBottom = 2,
    VMSAlignMiddle = 3,
    VMSAlignLeft = 4,
    VMSAlignRight = 5,
    VMSAlignCenter = 6,
} VMSAlignment;

#ifndef VMS_BASE_CONTROL_DEFAULT
#define VMS_BASE_CONTROL_DEFAULT
#define VMSControlPadding 5
#define VMSControlMargin 5
#endif

@interface VTMBaseControl () {
    @protected __weak MGLMapView* _mapView;
    @protected int marginTop;
    @protected int marginBottom;
    @protected int marginLeft;
    @protected int marginRight;
    
    @protected int horizontalAlign;
    @protected int verticalAlign;
}

- (void)createControl;
- (void)updateControl;

@end
