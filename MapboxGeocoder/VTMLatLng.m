//
//  VMSLatLng.m
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/12/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VTMLatLng.h"

@implementation VTMLatLng {
    double _latitude;
    double _longitude;
}

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

- (id)initWithLat:(double)lat lng:(double)lng {
    self = [super init];
    if (self) {
        _latitude = lat;
        _longitude = lng;
    }
    return self;
}

- (id)init:(VTMLatLng *)pt {
    self = [super init];
    if (self) {
        _latitude = pt.latitude;
        _longitude = pt.longitude;
    }
    return self;
}

- (VTMLatLng *)clone {
    return [[VTMLatLng alloc] initWithLat:self.latitude lng:self.longitude];
}

- (BOOL)isEqualToLatLng:(VTMLatLng *)pt {
    if (self.latitude == pt.latitude && self.longitude == pt.longitude) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)toUrlValue {
    return [NSString stringWithFormat:@"%f,%f", self.latitude, self.longitude];
}

- (NSString *)toUrlValueEx {
    return [NSString stringWithFormat:@"%f,%f", self.longitude, self.latitude];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"GeoPoint[%f,%f]", self.latitude, self.longitude];
}

- (id)copyWithZone:(NSZone *)zone {
    VTMLatLng *pt = [[[self class] allocWithZone:zone] init];
    if(pt) {
        [pt setLatitude:self.latitude];
        [pt setLongitude:self.longitude];
    }
    return pt;
}


// Them phan nay de save user default
- (void)encodeWithCoder:(NSCoder *)encoder
{
    //Encode properties, other class variables, etc
    [encoder encodeDouble:self.latitude forKey:@"latitude"];
    [encoder encodeDouble:self.longitude forKey:@"longitude"];
    
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if( self != nil )
    {
        //decode properties, other class vars
        self.latitude = [decoder decodeDoubleForKey:@"latitude"];
        self.longitude = [decoder decodeDoubleForKey:@"longitude"];
    }
    return self;
}

@end
