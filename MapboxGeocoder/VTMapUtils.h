//
//  VMSMapUtils.h
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/12/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import <UIKit/UIKit.h>

double const VMSFloorValue = 1e6;
typedef enum {
    VMSEncryptEarthPoint = 1,
    VMSEncryptDistancePoint = 2,
} VMSEncryptType;

@interface VTMapUtils : NSObject

/**
 * Ham tien ich decode chuoi ma hoa toa do cua cac dich vu viettelmap
 */
+ (NSMutableArray *)decodePoints:(NSString *)encodedString withType:(int)encryptedType;
@end
