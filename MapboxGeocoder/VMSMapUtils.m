//
//  VMSMapUtils.m
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/12/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import <mach/mach.h>
#import <mach/mach_host.h>
#import "VMSMapUtils.h"
#import "VMSLatLng.h"

@implementation VMSMapUtils

+ (NSMutableArray *)decodePoints:(NSString *)encodedString withType:(int)encryptedType {
    BOOL isSetPoint = NO;
    double precision = 1 / VMSFloorValue;
    int len = [encodedString length];
    int index = 0;
    if(len <= 0) {
        return nil;
    }
    
    NSMutableArray *points = [[NSMutableArray alloc] init];
    int b, shift, result;
    int lat, lng;
    if(encryptedType == VMSEncryptDistancePoint) {
        VMSLatLng *pt = [[VMSLatLng alloc] init];

        if (index < len) {
            shift = 0;
            result = 0;
            do {
                b = [encodedString characterAtIndex:index] - 63;
                index = index + 1;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            if ((result & 0x01) != 0)
                lat = ~(result >> 1);
            else
                lat = (result >> 1);
            
            // Tinh longitude
            shift = 0;
            result = 0;
            do {
                b = [encodedString characterAtIndex:index] - 63;
                index = index + 1;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            if ((result & 1) != 0)
                lng = ~(result >> 1);
            else
                lng = (result >> 1);
            
            [pt setLatitude:(lat * precision)];
            [pt setLongitude:(lng * precision)];
            isSetPoint = YES;
        }
        
        if (isSetPoint) {
            // Tinh tiep cac diem tiep theo
            [points addObject : pt];
            int latOff, lonOff;
            VMSLatLng *ptOld = [[VMSLatLng alloc] init:pt];
            while (index < len) {
                // Tinh latitude offset
                shift = 0;
                result = 0;
                do {
                    b = [encodedString characterAtIndex:index] - 63;
                    index = index + 1;
                    result |= (b & 0x1f) << shift;
                    shift += 5;
                } while (b >= 0x20);
                if ((result & 0x01) != 0)
                    latOff = ~(result >> 1);
                else
                    latOff = (result >> 1);
                
                // Tinh longitude offset
                shift = 0;
                result = 0;
                do {
                    b = [encodedString characterAtIndex:index] - 63;
                    index = index + 1;
                    result |= (b & 0x1f) << shift;
                    shift += 5;
                } while (b >= 0x20);
                if ((result & 1) != 0)
                    lonOff = ~(result >> 1);
                else
                    lonOff = (result >> 1);
                
                [pt setLatitude:(ptOld.latitude + latOff * precision)];
                [pt setLongitude:(ptOld.longitude + lonOff * precision)];
                [points addObject : pt];
                [ptOld setLatitude:pt.latitude];
                [ptOld setLongitude:pt.longitude];
            }
        }
    } else {
        while (index < len) {
            // Tinh latitude
            shift = 0;
            result = 0;
            do {
                b = [encodedString characterAtIndex:index] - 63;
                index = index + 1;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            if ((result & 0x01) != 0)
                lat = ~(result >> 1);
            else
                lat = (result >> 1);
            
            // Tinh longitude
            shift = 0;
            result = 0;
            do {
                b = [encodedString characterAtIndex:index] - 63;
                index = index + 1;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            if ((result & 1) != 0)
                lng = ~(result >> 1);
            else
                lng = (result >> 1);
            
            VMSLatLng *pt = [[VMSLatLng alloc] initWithLat:(lat * precision) lng:(lng * precision)];
            [points addObject : pt];
        }
    }
    
    return points;
}
@end
