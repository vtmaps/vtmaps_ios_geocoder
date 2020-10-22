//
//  VMSGPSControlNew.m
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/18/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import "VTMGPSControl.h"
//#import "VMSMapView.h"
//#import "VMSProjection.h"
//#import "VMSLatLngBounds.h"
#import "UIKit/UIKit.h"
#import "VTMBaseControl_Ext.h"
//#import "VMSGeometryUtils.h"
//#import "VMSMapUtils.h"
#import <Mapbox/Mapbox.h>

@interface VTMGPSControl () <CLLocationManagerDelegate> {
    //UIButton *_myLocationBtn;
    CLLocationManager *_locationManager;
    CLLocation *_currentLocation;
    CLHeading *_currentHeading;
    __weak id<VMSGPSNewDelegate> _delegate;
    
    UIImage *_locationIcon;
    UIImage *_directionIcon;
    
    NSTimer *_timer;
}

@end

@implementation VTMGPSControl

#define TIME_INTERVAL_UPDATE_LOCATION 4
#define TIME_OUT_UPDATE_LOCATION 2
#define LOCATION_ACCURACY_DESIRE 500
#define MIN_DISTANCE_GPS_UPDATE 10
#define INTERVAL_GPS_UPDATE 30
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@synthesize delegate = _delegate;

- (void)initResource {
    _locationIcon = [UIImage imageNamed:@"vtmap_ic_location_point"];
    _directionIcon = [UIImage imageNamed:@"vtmap_ic_location_direction"];
}

- (id)initWithMap:(MGLMapView *)map delegate:(id<VMSGPSNewDelegate>) delegate {
    self = [super initWithMap:map];
    if (self) {
        [self initResource];
        self.delegate = delegate;
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer; //kCLLocationAccuracyBest;
        _locationManager.distanceFilter = MIN_DISTANCE_GPS_UPDATE;
        _locationManager.delegate = self;
        
        [self createControl];
    }
    return self;
}

- (void)setDesiredAccturacy: (CLLocationAccuracy) desiredAccuracy {
    _locationManager.desiredAccuracy = desiredAccuracy;
}
- (void)setDistanceFilter: (CLLocationDistance) distanceFilter {
    _locationManager.distanceFilter = distanceFilter;
}

#pragma mark - delegate from location Manager
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    // Xac dinh moc thoi gian xac dinh dinh vi. Dam bao ko phai gia tri cache
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) {
        NSLog(@"locationAge > 5.0");
        return;
    }
    
    // Do chinh xac ngang neu am thi la ko hop le
    if (newLocation.horizontalAccuracy < 0) {
        NSLog(@"newLocation.horizontalAccuracy < 0");
        return;
    }
    
    NSLog(@"newLocation lat: %f, long: %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    
    float accuracy = newLocation.horizontalAccuracy;
    NSLog(@"newLocation Do chinh xac ngang: %f", accuracy);
    NSLog(@"old Do chinh xac ngang: %f", _currentLocation.horizontalAccuracy);
    
    if (accuracy < kCLLocationAccuracyThreeKilometers) {
        NSLog(@"kCLLocationAccuracyThreeKilometers");
        
    } else if (accuracy < kCLLocationAccuracyKilometer) {
        NSLog(@"kCLLocationAccuracyKilometer");
        
    } else if (accuracy < kCLLocationAccuracyHundredMeters) {
        NSLog(@"kCLLocationAccuracyHundredMeters");
        
    } else if (accuracy < kCLLocationAccuracyNearestTenMeters) {
        NSLog(@"kCLLocationAccuracyNearestTenMeters");
        
    } else if (accuracy < kCLLocationAccuracyBest) {
        NSLog(@"kCLLocationAccuracyBest");
    }

    BOOL isFirst = (_currentLocation == nil);
    if (newLocation != nil) {
        // chi lay lai vi tri neu chinh xac hon lan truoc
        if (isFirst // lan dau tien vao
            || _currentLocation.horizontalAccuracy >= accuracy //lay lai vi tri neu chinh xac hon lan truoc
            || newLocation.course >= 0) { // dang di chuyen thi cap nhat lien tuc
            
            NSLog(@"isFirst || _currentLocation.horizontalAccuracy > newLocation.horizontalAccuracy");
            _currentLocation = [newLocation copy];
        } else {
            NSLog(@"========================================================not satisfy newLocation");
            return;
        }
    }
    
    if (isFirst && _currentLocation != nil) {
        [self goToMyLocation:_myLocationBtn];
    }
    else if (_currentLocation != nil) {
        [self updateMyLocation];
    }
    
    //    [self stopUpdateLocation];
    
    if (_delegate != nil) {
        if ([_delegate respondsToSelector:@selector(locationUpdate:)]) {
            [_delegate locationUpdate:_currentLocation];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    _currentLocation = nil;
    [self stopUpdateLocation];
    [self startUpdateLocation];
    if (_delegate != nil) {
        if ([_delegate respondsToSelector:@selector(locationError:)]) {
            [_delegate locationError:error];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            self.mapView.showsUserLocation = false;
            break;
        case kCLAuthorizationStatusRestricted:
            self.mapView.showsUserLocation = false;
            break;
        case kCLAuthorizationStatusDenied :
            self.mapView.showsUserLocation = false;
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
            self.mapView.showsUserLocation = true;
            [_locationManager startUpdatingLocation];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse :
            self.mapView.showsUserLocation = true;
            [_locationManager startUpdatingLocation];
            break;
        default:
            break;
    }
}

-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    if (self.mapView) {
        CLLocation *currentLoc = locations.lastObject;
        if (nil == currentLoc) {
            return;
        }
        //old code
        // Xac dinh moc thoi gian xac dinh dinh vi. Dam bao ko phai gia tri cache
        NSTimeInterval locationAge = -[currentLoc.timestamp timeIntervalSinceNow];
        if (locationAge > 5.0) {
            NSLog(@"locationAge > 5.0");
            return;
        }
        
        // Do chinh xac ngang neu am thi la ko hop le
        if (currentLoc.horizontalAccuracy < 0) {
            NSLog(@"newLocation.horizontalAccuracy < 0");
            return;
        }
        
        NSLog(@"newLocation lat: %f, long: %f", currentLoc.coordinate.latitude, currentLoc.coordinate.longitude);
        
        float accuracy = currentLoc.horizontalAccuracy;
        NSLog(@"newLocation Do chinh xac ngang: %f", accuracy);
        NSLog(@"old Do chinh xac ngang: %f", _currentLocation.horizontalAccuracy);
        
        if (accuracy < kCLLocationAccuracyThreeKilometers) {
            NSLog(@"kCLLocationAccuracyThreeKilometers");
            
        } else if (accuracy < kCLLocationAccuracyKilometer) {
            NSLog(@"kCLLocationAccuracyKilometer");
            
        } else if (accuracy < kCLLocationAccuracyHundredMeters) {
            NSLog(@"kCLLocationAccuracyHundredMeters");
            
        } else if (accuracy < kCLLocationAccuracyNearestTenMeters) {
            NSLog(@"kCLLocationAccuracyNearestTenMeters");
            
        } else if (accuracy < kCLLocationAccuracyBest) {
            NSLog(@"kCLLocationAccuracyBest");
        }

        BOOL isFirst = (_currentLocation == nil);
        if (currentLoc != nil) {
            // chi lay lai vi tri neu chinh xac hon lan truoc
            if (isFirst // lan dau tien vao
                || _currentLocation.horizontalAccuracy >= accuracy //lay lai vi tri neu chinh xac hon lan truoc
                || currentLoc.course >= 0) { // dang di chuyen thi cap nhat lien tuc
                
                NSLog(@"isFirst || _currentLocation.horizontalAccuracy > newLocation.horizontalAccuracy");
                _currentLocation = [currentLoc copy];
            } else {
                NSLog(@"========================================================not satisfy newLocation");
                return;
            }
        }
        
        if (isFirst && _currentLocation != nil) {
            [self goToMyLocation:_myLocationBtn];
        }
        else if (_currentLocation != nil) {
            [self updateMyLocation];
        }
        
        //add new
        //----------------------------------------------------------------------
        self.mapView.showsUserLocation = true;
        CLLocationCoordinate2D currentLoc2D = CLLocationCoordinate2DMake(currentLoc.coordinate.latitude, currentLoc.coordinate.longitude);
        [self.mapView setCenterCoordinate:currentLoc2D zoomLevel:17.0 direction:2 animated:true];
    }
    [_locationManager stopUpdatingLocation];
    
    if (_delegate != nil) {
        if ([_delegate respondsToSelector:@selector(locationUpdate:)]) {
            [_delegate locationUpdate:_currentLocation];
        }
    }
}


#pragma mark - control GPS
- (IBAction)goToMyLocation:(id)sender {
//    if (_currentLocation == nil) {
        [self enableGPS];
//        return;
//    }
    
//    [self updateGPSLocationObject];
    if (self.mapView) {
        CLLocation *currentLoc = [self getMyLocation];
        if (nil == currentLoc) {
            return;
        }
        self.mapView.showsUserLocation = true;
        CLLocationCoordinate2D currentLoc2D = CLLocationCoordinate2DMake(currentLoc.coordinate.latitude, currentLoc.coordinate.longitude);
        [self.mapView setCenterCoordinate:currentLoc2D zoomLevel:17.0 direction:2 animated:true];
    }
}

- (void)updateGPSLocationObject {
    
}

- (void)updateMyLocation {
    if (self.mapView == nil) {
        return;
    }
    CLLocation *pt = [self getMyLocation];
    if (pt == nil) {
        return;
    }
    
    // update location
    [self updateGPSLocationObject];
    
    // Set lai bounds cho map
//    VMSLatLngBounds *bound = self.mapView.projection.mapBoundary;
//    if ([bound contains:pt]) {
//        [self.mapView refresh];
//    }
}

// Ham nay dang khong hop ly khi chi lay vi tri hien tai truoc day
- (CLLocation *)getMyLocation {
    if (_currentLocation == nil) {
        return nil;
    }
    if (nil == self.mapView.userLocation || nil == self.mapView.userLocation.location) {
        return nil;
    }
    CLLocation *currentLoc = [[CLLocation alloc] initWithLatitude:self.mapView.userLocation.location.coordinate.latitude longitude: self.mapView.userLocation.location.coordinate.longitude];
    return currentLoc;
}

- (void)startUpdateLocation {
    if (_locationManager != nil) {
        [_locationManager stopUpdatingLocation];
        [_locationManager startUpdatingLocation];
    }
}

- (void)stopUpdateLocation {
    if (_locationManager != nil) {
        [_locationManager stopUpdatingLocation];
    }
}

- (void)timerUpdateLocation {
    [_locationManager startUpdatingHeading];
}

- (void)enableGPS {
    BOOL locationEnabled = [CLLocationManager locationServicesEnabled];
    if (locationEnabled == NO || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        UIAlertView *locationAlert = nil;
        
        NSString *titleOther = nil;
        if(IS_OS_8_OR_LATER) {
            titleOther = @"Settings";
        }
        locationAlert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"Location service is currently disabled. Please go to Setting and turn on Location Service for this application." delegate:self cancelButtonTitle:@"Confirm" otherButtonTitles:titleOther, nil];
        [locationAlert show];
        return;
    }
    
    if (_timer != nil) {
        [self disableGPS];
    }
    
    [self startUpdateLocation];
    _timer = [NSTimer scheduledTimerWithTimeInterval:INTERVAL_GPS_UPDATE target:self selector:@selector(timerUpdateLocation) userInfo:nil repeats:YES];
}

- (void)disableGPS {
    if (_timer != nil) {
        [_timer invalidate];
        _timer = nil;
    }
    //    [self stopUpdateLocation];
}

- (void)createControl {
    NSString *iconName = @"vtmap_ic_btn_gps";
    NSBundle *frameWorkBundle = [NSBundle bundleForClass:[self class]];
    UIImage *icon = [UIImage imageNamed:iconName inBundle:frameWorkBundle compatibleWithTraitCollection:nil];
    
    CGRect btnRect = CGRectMake(0, 0, icon.size.width, icon.size.height);
    if(self.mapView){
        //btnRect = CGRectMake(self.mapView.frame.size.width - icon.size.width - 30, self.mapView.frame.size.height - icon.size.height - 30 , icon.size.width, icon.size.height);
    }
    
    if(CGRectEqualToRect(self.frame, CGRectZero)) {
        int offsetX = 0;
        int offsetY = 0;
        if (self.mapView != nil) {
            offsetX = VMSControlMargin;
            offsetY = VMSControlMargin;
        }
        self.frame = CGRectMake(offsetX, offsetY, icon.size.width, icon.size.height);
    }
    
    _myLocationBtn = [[UIButton alloc] initWithFrame:btnRect];
    [_myLocationBtn setBackgroundImage:icon forState:UIControlStateNormal];
    [_myLocationBtn addTarget:self action:@selector(goToMyLocation:) forControlEvents:UIControlEventTouchUpInside];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
    [self addSubview:_myLocationBtn];
    
    if (self.mapView) {
        [self.mapView addSubview:self];
    }
}

- (void)setControl {
    
}

- (void)setEnabledControl:(BOOL)enabled {
    if (_myLocationBtn != nil) {
        [_myLocationBtn setEnabled:enabled];
    }
}

- (void)updateControl {
    return;
}

#pragma mark - Delegate from alertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Send the user to the Settings for this app
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
}

#pragma mark - memory
- (void)dealloc {
    if (_locationManager) {
        [self stopUpdateLocation];
        _locationManager = nil;
    }
    if (_myLocationBtn) {
        [_myLocationBtn removeFromSuperview];
        _myLocationBtn = nil;
    }
    if (_locationIcon) {
        _locationIcon = nil;
    }
    if (_directionIcon) {
        _directionIcon = nil;
    }
    if (_delegate) {
        _delegate = nil;
    }
    if(_myLocationBtn){
        _myLocationBtn = nil;
    }
}

- (void)setMapView:(MGLMapView *)mapView {
    _mapView = mapView;
}

@end
