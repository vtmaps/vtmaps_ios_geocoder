#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#if !TARGET_OS_TV
#import <Contacts/Contacts.h>
#endif

FOUNDATION_EXPORT double MapboxGeocoderVersionNumber;

FOUNDATION_EXPORT const unsigned char MapboxGeocoderVersionString[];

#import "MBPlacemarkPrecision.h"
#import "MBPlacemarkScope.h"
#import "VMSMapUtils.h"
#import "VMSLatLng.h"
