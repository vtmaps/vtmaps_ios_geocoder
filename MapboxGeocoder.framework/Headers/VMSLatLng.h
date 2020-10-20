//
//  VMSLatLng.h
//  VTMapAPI
//
#import <UIKit/UIKit.h>

@interface VMSLatLng : NSObject

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;

// Khoi tao object su dung kinh do, vi do
- (id)initWithLat:(double) lat lng:(double)lng;

// Khoi tao object thong qua VMSLatLng co san, tuong duong clone object
- (id)init:(VMSLatLng *)pt;

// Tra lai 1 doi tuong VMSLatLng co gia tri tuong ung
- (VMSLatLng *)clone;

// Kiem tra 2 doi tuong VMSLatLng co gia tri bang nhau hay khong
- (BOOL)isEqualToLatLng:(VMSLatLng *)pt;

// Tra ve chuoi string gia tri cua VMSLatLng theo dinh dang "Latitude, Longitude"
- (NSString *)toUrlValue;

// Tra ve chuoi string gia tri cua VMSLatLng theo dinh dang "Longitude, Latitude"
- (NSString *)toUrlValueEx;

// Tra ve chuoi string gia tri cua VMSLatLng theo dinh dang "GeoPoint[Latitude, Longitude]"
- (NSString *)toString;

// Thay doi gia tri thuoc tinh cua VMSLatLng giua cac he truc toa do
- (VMSLatLng *)transformFromSRS:(int)srsSRS toSRS:(int)desSRS;

@end
