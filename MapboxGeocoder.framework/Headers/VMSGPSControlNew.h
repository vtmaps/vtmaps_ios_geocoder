//
//  VMSGPSControlNew.h
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/18/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VMSBaseControl.h"
#import <CoreLocation/CoreLocation.h>
//#import "VMSLatLng.h"
//#import "VMSMapLayer.h"
//#import "VMSMapObject.h"
//#import "VMSCircle.h"
//#import "VMSCircleOptions.h"
//#import "VMSMarker.h"
//#import "VMSMarkerOptions.h"
//#import "VMSVectorLayer.h"
//#import "VMSMarkerLayer.h"

/**
 * Delegate lắng nghe các sự kiện của GPSControl
 */
@protocol VMSGPSNewDelegate <NSObject>
@required
- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;
@end


/**
 * Control quản lý GPS
 */
@interface VMSGPSControlNew : VMSBaseControl

/**
 * Delegate cho các sự kiện update / error của GPS
 */
@property (nonatomic, weak) id<VMSGPSNewDelegate> delegate;

/**
 * Hàm khởi tạo GPS control theo map có sử dụng delegate
 */
- (id)initWithMap:(MGLMapView *)map delegate:(id<VMSGPSNewDelegate>) delegate;

/**
 * Hàm tiện ích request map di chuyển đến điểm GPS hiện tại của người sử dụng
 * Trong trường hợp chương trình không xác định được GPS của người sử dụng thì không thể di chuyển
 */
- (IBAction)goToMyLocation:(id)sender;

/**
 * Hàm request GPSControl update lại icon hiển thị điểm GPS hiện tại
 */
- (void)updateGPSLocationObject;

/**
 * Hàm request GPSControl update lại vị trí GPS hiện tại
 */
- (void)updateMyLocation;

/**
 * Ngừng update lại vị trí GPS hiện tại
 */
- (void)stopUpdateLocation;

/**
 * Lấy toạ độ GPS hiện tại của người sử dụng
 */
- (CLLocation *)getMyLocation;

/**
 * Bật GPS control
 */
- (void)enableGPS;

/**
 * Tắt GPS control
 */
- (void)disableGPS;

/**
 *  Set thong so quy dinh sai so khi su dung GPS
 *      kCLLocationAccuracyBest;
 *      kCLLocationAccuracyNearestTenMeters;
 *      kCLLocationAccuracyHundredMeters;
 *      kCLLocationAccuracyKilometer;
 *      kCLLocationAccuracyThreeKilometers;
 *  Tuy vao yeu cau bai toan de lua chon sai so.
 *  No co the gay ton pin thiet bi, xu ly cham khi su dung khong dung muc dich
 *  Hien tai API dang de gia tri default kCLLocationAccuracyBest
 *
 *  Chu y: Khi chon do chinh xac < kCLLocationAccuracyKilometer thi o iPhone 6 tro len
 *      se gap loi request xac dinh vi tri lien tuc
 *      ==> KL: hien tai iPhone 6 chi co do chinh xac ~ kCLLocationAccuracyKilometer
 */
- (void)setDesiredAccturacy: (CLLocationAccuracy) desiredAccuracy;

/**
 *  Day la thong so quy dinh khoang cach toi thieu (tinh theo met) update vi tri
 *  No co the gay ton pin thiet bi, xu ly cham khi su dung khong dung muc dich
 *  Thong thuong se su dung kCLDistanceFilterNone, tuc la luon update vi tri khi chuyen dong
 *  Hien tai API dang de gia tri default la 10 (m)
 */
- (void)setDistanceFilter: (CLLocationDistance) distanceFilter;



@end
