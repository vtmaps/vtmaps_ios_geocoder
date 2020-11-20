//
//  VTMMapTypeControl.m
//  VTMapAPI
//
//  Created by Nguyen Van Tho on 11/13/13.
//  Copyright (c) 2013 Viettel. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "VTMBaseControl_Ext.h"
#import "VTMMapTypeControl.h"
#import <Mapbox/Mapbox.h>

@interface VTMMapTypeControl () {
    __weak id<VTMMapStyleDelegate> _delegate;
}
@end

@implementation VTMMapTypeControl {
    @private UIButton *btnMapType;
    @private BOOL enableMapTypeTerrain;
    @private BOOL enableMapTypeSattelite;
}

@synthesize delegate = _delegate;

- (id)initWithMap:(MGLMapView *)map delegate:(id<VTMMapStyleDelegate>) delegate {
    self = [super initWithMap:map];
    if (self) {
        self.delegate = delegate;
        [self createControl];
        [self updateControl];
    }
    return self;
}

-(NSString *) LocalizedString : (NSString *) key {
    return NSLocalizedStringFromTableInBundle(key, @"", [NSBundle bundleForClass:[self class]], @"");
}

-(NSString *) getMapTypeText {
    VTMMapType mapType = [self getMapTypeOfVTMap];
    NSString *mapTypeText = [self LocalizedString: @"TXT_MAPSTYPE_TRANSPORT"];
    if (mapType == VTMMapTypeTransport) {
        mapTypeText = [self LocalizedString: @"TXT_MAPSTYPE_TRANSPORT"];
    }else if (mapType == VTMMapTypeAdmin) {
        mapTypeText = [self LocalizedString: @"TXT_MAPSTYPE_ADMIN"];
    }else if (mapType == VTMMapTypeTerrain) {
        mapTypeText = [self LocalizedString: @"TXT_MAPSTYPE_TERRAIN"];
    }else if (mapType == VTMMapTypeSattelite) {
        mapTypeText = [self LocalizedString: @"TXT_MAPSTYPE_SATTELITE"];
    }else{
        mapTypeText = [self LocalizedString: @"TXT_MAPSTYPE_TRANSPORT"];
    }
    return mapTypeText;
}

-(UILabel *) getMapTypeLabelWithSize: (CGRect) frameRect {
    NSString *mapTypeText = [self getMapTypeText];
    UILabel *maptypeLabel = [[UILabel alloc]initWithFrame:frameRect];
    maptypeLabel.tag = 1;
    UIColor *color = [UIColor whiteColor];
    [maptypeLabel setTextColor:color];
    maptypeLabel.text = mapTypeText;
    //maptypeLabel.adjustsFontSizeToFitWidth = YES;
    maptypeLabel.font=[maptypeLabel.font fontWithSize:9];
    maptypeLabel.textAlignment = NSTextAlignmentCenter;
    maptypeLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    CGRect bounds = maptypeLabel.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                                             cornerRadii:CGSizeMake(8.0, 8.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    maptypeLabel.layer.mask = maskLayer;
    return maptypeLabel;
}

- (void)createControl {
    
    VTMMapType mapType;
    mapType = [self getMapTypeOfVTMap];
    
    if (mapType == VTMMapTypeTerrain) {
        enableMapTypeTerrain = true;
    }else{
        enableMapTypeTerrain = false;
    }
        
    if (mapType == VTMMapTypeSattelite) {
        enableMapTypeSattelite = true;
    }else{
        enableMapTypeSattelite = false;
    }
    
    NSString *iconName = [NSString stringWithFormat:@"vtmap_ic_btn_layer_%d.png", mapType];
    NSBundle *frameWorkBundle = [NSBundle bundleForClass:[self class]];
    UIImage *icon = [UIImage imageNamed:iconName inBundle:frameWorkBundle compatibleWithTraitCollection:nil];
    
    if(CGRectEqualToRect(self.frame, CGRectZero)) {
        int offsetX = 0;
        if (self.mapView) {
            offsetX = self.mapView.frame.size.width - icon.size.width - VMSMapTypeControlMargin;
        }
        self.frame = CGRectMake(offsetX, VMSMapTypeControlMargin, icon.size.width, icon.size.height);
    }
    btnMapType = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, icon.size.width, icon.size.height)];
    [btnMapType setBackgroundImage:icon forState:UIControlStateNormal];
    btnMapType.layer.masksToBounds = YES;
    btnMapType.layer.cornerRadius = 8.0f;
    //btnMapType.layer.borderWidth = 1.0f;
	btnMapType.layer.borderColor = [UIColor grayColor].CGColor;
    
    UILabel *maptypeLabel = [self getMapTypeLabelWithSize: CGRectMake(0, icon.size.height - 18, icon.size.width, 18)];
    [btnMapType addSubview:maptypeLabel];
    [btnMapType bringSubviewToFront:maptypeLabel];
    
    [btnMapType addTarget:self action:@selector(changeMapLayer:) forControlEvents:UIControlEventTouchUpInside];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin];
    [self addSubview:btnMapType];
    
    if (self.mapView != nil) {
        [self.mapView addSubview:self];
        [self.mapView bringSubviewToFront:self];
    }
}

- (VTMMapType) getMapTypeOfVTMap{
    BOOL debugMode = [[NSBundle mainBundle].infoDictionary[@"VTMapDebugMode"] boolValue];
    if(debugMode){
        return [self getMapTypeOfVTMapStaging];
    }else{
        return [self getMapTypeOfVTMapProduction];
    }
}

- (VTMMapType) getMapTypeOfVTMapProduction{
    NSString *BASE_URL = @"https://api.viettelmaps.vn/gateway/mapservice/v1/media/";
    NSString *VTMAP_TRAFFIC_DAY= [NSString stringWithFormat:@"%@style.json", BASE_URL];// giao thong
    NSString *VTMAP_ADMIN = [NSString stringWithFormat:@"%@style-admin.json", BASE_URL]; //hanh chinh
    NSString *VTMAP_GTRANS = [NSString stringWithFormat:@"%@gtrans_style.json", BASE_URL]; //google
    NSString *VTMAP_GSAT = [NSString stringWithFormat:@"%@gsat_style.json", BASE_URL]; // ve tinh
    
    NSURL *URL_VTMAP_TRAFFIC_DAY = [NSURL URLWithString:VTMAP_TRAFFIC_DAY];
    NSURL *URL_VTMAP_ADMIN = [NSURL URLWithString:VTMAP_ADMIN];
    NSURL *URL_VTMAP_GTRANS = [NSURL URLWithString:VTMAP_GTRANS];
    NSURL *URL_VTMAP_GSAT = [NSURL URLWithString:VTMAP_GSAT];
    
    VTMMapType mapType;
    if (self.mapView) {
        if ([self.mapView.styleURL isEqual:URL_VTMAP_TRAFFIC_DAY]) {
            mapType = VTMMapTypeTransport;
        }else if ([self.mapView.styleURL isEqual: URL_VTMAP_ADMIN]) {
            mapType = VTMMapTypeAdmin;
        }else if ([self.mapView.styleURL isEqual: URL_VTMAP_GTRANS]) {
            mapType = VTMMapTypeTerrain;
        }else if ([self.mapView.styleURL isEqual: URL_VTMAP_GSAT]) {
            mapType = VTMMapTypeSattelite;
        }else{
            mapType = VTMMapTypeTransport;
        }
    }else{
        mapType = VTMMapTypeTransport;
    }
    return mapType;
}

- (VTMMapType) getMapTypeOfVTMapStaging{
    
    NSString *BASE_URL = @"https://api.viettelmaps.com.vn:8080/gateway/mapservice/v1/media/";
    NSString *VTMAP_TRAFFIC_DAY= [NSString stringWithFormat:@"%@style.json", BASE_URL];// giao thong
    NSString *VTMAP_ADMIN = [NSString stringWithFormat:@"%@style-admin.json", BASE_URL]; //hanh chinh
    NSString *VTMAP_GTRANS = [NSString stringWithFormat:@"%@gtrans_style.json", BASE_URL]; //google
    NSString *VTMAP_GSAT = [NSString stringWithFormat:@"%@gsat_style.json", BASE_URL]; // ve tinh
    
    NSURL *URL_VTMAP_TRAFFIC_DAY = [NSURL URLWithString:VTMAP_TRAFFIC_DAY];
    NSURL *URL_VTMAP_ADMIN = [NSURL URLWithString:VTMAP_ADMIN];
    NSURL *URL_VTMAP_GTRANS = [NSURL URLWithString:VTMAP_GTRANS];
    NSURL *URL_VTMAP_GSAT = [NSURL URLWithString:VTMAP_GSAT];
    
    VTMMapType mapType;
    if (self.mapView) {
        if ([self.mapView.styleURL isEqual:URL_VTMAP_TRAFFIC_DAY]) {
            mapType = VTMMapTypeTransport;
        }else if ([self.mapView.styleURL isEqual: URL_VTMAP_ADMIN]) {
            mapType = VTMMapTypeAdmin;
        }else if ([self.mapView.styleURL isEqual: URL_VTMAP_GTRANS]) {
            mapType = VTMMapTypeTerrain;
        }else if ([self.mapView.styleURL isEqual: URL_VTMAP_GSAT]) {
            mapType = VTMMapTypeSattelite;
        }else{
            mapType = VTMMapTypeTransport;
        }
    }else{
        mapType = VTMMapTypeTransport;
    }
    return mapType;
}

- (void) setMapTypeForVTMap:(VTMMapType) mapType{
    
    if(mapType == VTMMapTypeTerrain || mapType == VTMMapTypeSattelite){
        if(enableMapTypeTerrain == false && enableMapTypeSattelite == false){
            mapType = VTMMapTypeTransport;
        }else{
            if(mapType == enableMapTypeTerrain && enableMapTypeTerrain == false){
                mapType = VTMMapTypeSattelite;
            }
            if(mapType == VTMMapTypeSattelite && enableMapTypeSattelite == false){
                mapType = VTMMapTypeTransport;
            }
        }
    }
    BOOL debugMode = [[NSBundle mainBundle].infoDictionary[@"VTMapDebugMode"] boolValue];
    if(debugMode){
        [self setMapTypeForVTMapStaging: mapType];
    }else{
        [self setMapTypeForVTMapProduction: mapType];
    }
}

- (void) setMapTypeForVTMapStaging:(VTMMapType) mapType{
    NSString *BASE_URL = @"https://api.viettelmaps.com.vn:8080/gateway/mapservice/v1/media/";
    NSString *VTMAP_TRAFFIC_DAY= [NSString stringWithFormat:@"%@style.json", BASE_URL];// giao thong
    NSString *VTMAP_ADMIN = [NSString stringWithFormat:@"%@style-admin.json", BASE_URL]; //hanh chinh
    NSString *VTMAP_GTRANS = [NSString stringWithFormat:@"%@gtrans_style.json", BASE_URL]; //google
    NSString *VTMAP_GSAT = [NSString stringWithFormat:@"%@gsat_style.json", BASE_URL]; // ve tinh
    
    NSURL *URL_VTMAP_TRAFFIC_DAY = [NSURL URLWithString:VTMAP_TRAFFIC_DAY];
    NSURL *URL_VTMAP_ADMIN = [NSURL URLWithString:VTMAP_ADMIN];
    NSURL *URL_VTMAP_GTRANS = [NSURL URLWithString:VTMAP_GTRANS];
    NSURL *URL_VTMAP_GSAT = [NSURL URLWithString:VTMAP_GSAT];
    
    if (self.mapView) {
        if (mapType == VTMMapTypeTransport) {
            self.mapView.styleURL = URL_VTMAP_TRAFFIC_DAY;
        }else if (mapType == VTMMapTypeAdmin) {
            self.mapView.styleURL = URL_VTMAP_ADMIN;
        }else if (mapType == VTMMapTypeTerrain) {
            self.mapView.styleURL = URL_VTMAP_GTRANS;
        }else if (mapType == VTMMapTypeSattelite) {
            self.mapView.styleURL = URL_VTMAP_GSAT;
        }else{
            self.mapView.styleURL = URL_VTMAP_TRAFFIC_DAY;
        }
    }else{
        self.mapView.styleURL = URL_VTMAP_TRAFFIC_DAY;
    }
}

- (void) setMapTypeForVTMapProduction:(VTMMapType) mapType{
   NSString *BASE_URL = @"https://api.viettelmaps.vn/gateway/mapservice/v1/media/";
    NSString *VTMAP_TRAFFIC_DAY= [NSString stringWithFormat:@"%@style.json", BASE_URL];// giao thong
    NSString *VTMAP_ADMIN = [NSString stringWithFormat:@"%@style-admin.json", BASE_URL]; //hanh chinh
    NSString *VTMAP_GTRANS = [NSString stringWithFormat:@"%@gtrans_style.json", BASE_URL]; //google
    NSString *VTMAP_GSAT = [NSString stringWithFormat:@"%@gsat_style.json", BASE_URL]; // ve tinh
    
    NSURL *URL_VTMAP_TRAFFIC_DAY = [NSURL URLWithString:VTMAP_TRAFFIC_DAY];
    NSURL *URL_VTMAP_ADMIN = [NSURL URLWithString:VTMAP_ADMIN];
    NSURL *URL_VTMAP_GTRANS = [NSURL URLWithString:VTMAP_GTRANS];
    NSURL *URL_VTMAP_GSAT = [NSURL URLWithString:VTMAP_GSAT];
    
    if (self.mapView) {
        if (mapType == VTMMapTypeTransport) {
            self.mapView.styleURL = URL_VTMAP_TRAFFIC_DAY;
        }else if (mapType == VTMMapTypeAdmin) {
            self.mapView.styleURL = URL_VTMAP_ADMIN;
        }else if (mapType == VTMMapTypeTerrain) {
            self.mapView.styleURL = URL_VTMAP_GTRANS;
        }else if (mapType == VTMMapTypeSattelite) {
            self.mapView.styleURL = URL_VTMAP_GSAT;
        }else{
            self.mapView.styleURL = URL_VTMAP_TRAFFIC_DAY;
        }
    }else{
        self.mapView.styleURL = URL_VTMAP_TRAFFIC_DAY;
    }
}

- (void)updateControl {
    if (self.mapView != nil) {
        [self updateImageIcon:[self getMapTypeOfVTMap]];
        [self updateLabelText];
    }
}

- (VMSControlType)controlType {
    return VMSTypeControlMapType;
}

- (void)setMapType:(VTMMapType)mapType {
    if (self.mapView) {
        
        if (mapType == VTMMapTypeTerrain) {
            enableMapTypeTerrain = true;
        }else{
            enableMapTypeTerrain = false;
        }
            
        if (mapType == VTMMapTypeSattelite) {
            enableMapTypeSattelite = true;
        }else{
            enableMapTypeSattelite = false;
        }
        
        [self setMapTypeForVTMap:mapType];
        [self updateImageIcon:mapType];
        [self updateLabelText];
    }
}

- (IBAction)changeMapLayer:(id)sender {
    if (self.mapView == nil || btnMapType == nil) {
        // Don't have mapView or button yet, can't change image
        if (_delegate != nil) {
            if ([_delegate respondsToSelector:@selector(changedMapStyleError)]) {
                [_delegate changedMapStyleError];
            }
        }
        return;
    } else {
        VTMMapType mapType = self.nextMapType;
        [self setMapTypeForVTMap:mapType];
        [self updateImageIcon:mapType];
        [self updateLabelText];
        if (_delegate != nil) {
            if ([_delegate respondsToSelector:@selector(changedMapStyleSuccess:)]) {
                [_delegate changedMapStyleSuccess:mapType];
            }
        }
    }
}

- (VTMMapType)nextMapType {
    if (!self.mapView) {
        return VTMMapTypeTransport;
    }

    VTMMapType mapType = [self getMapTypeOfVTMap];
    if (VMSMapSRS == VMS_SRS900913) {
        switch (mapType) {
            case VTMMapTypeTransport:
                mapType = VTMMapTypeAdmin;
                break;
            case VTMMapTypeAdmin:
                mapType = VTMMapTypeTerrain;
                break;
            case VTMMapTypeTerrain:
                mapType = VTMMapTypeSattelite;
                break;
            case VTMMapTypeSattelite:
                mapType = VTMMapTypeTransport;
                break;
            default:
                mapType = VTMMapTypeTransport;
                break;
        }
    } else {
        switch (mapType) {
            case VTMMapTypeTransport:
                mapType = VTMMapTypeAdmin;
                break;
            case VTMMapTypeAdmin:
                mapType = VTMMapTypeTransport;
                break;
            default:
                mapType = VTMMapTypeTransport;
                break;
        }
    }
    return mapType;
}

- (void)updateLabelText {
    
    NSString *mapTypeText = [self getMapTypeText];
    
    for (UIView *i in btnMapType.subviews){
          if([i isKindOfClass:[UILabel class]]){
                UILabel *labelStyle = (UILabel *)i;
                if(labelStyle.tag == 1){
                    /// change string
                    labelStyle.text = mapTypeText;
                }
          }
    }
}

- (void)updateImageIcon:(VTMMapType)mapType {
    
    if(mapType == VTMMapTypeTerrain || mapType == VTMMapTypeSattelite){
        if(enableMapTypeTerrain == false && enableMapTypeSattelite == false){
            mapType = VTMMapTypeTransport;
        }else{
            if(mapType == enableMapTypeTerrain && enableMapTypeTerrain == false){
                mapType = VTMMapTypeSattelite;
            }
            if(mapType == VTMMapTypeSattelite && enableMapTypeSattelite == false){
                mapType = VTMMapTypeTransport;
            }
        }
    }
    
    NSString *iconName = [NSString stringWithFormat:@"vtmap_ic_btn_layer_%d.png", mapType];
    NSBundle *frameWorkBundle = [NSBundle bundleForClass:[self class]];
    UIImage *icon = [UIImage imageNamed:iconName inBundle:frameWorkBundle compatibleWithTraitCollection:nil];
    
    [btnMapType setBackgroundImage:icon forState:UIControlStateNormal];
//    if (self.mapView) {
//        [self.mapView refresh];
//    }
}

- (void)setEnabledControl:(BOOL)enabled {
    if (btnMapType) {
        [btnMapType setEnabled:enabled];
    }
}


- (void)enabledMapTypeTerrain:(BOOL)enabled {
    enableMapTypeTerrain = enabled;
}


- (void)enabledMapTypeSattelite:(BOOL)enabled {
    enableMapTypeSattelite = enabled;
}

- (BOOL)isMapTypeTerrainEnable {
    return enableMapTypeTerrain;
}


- (BOOL)isMapTypeSatteliteEnable {
    return enableMapTypeSattelite;
}



- (void) dealloc {
    if (btnMapType) {
        [btnMapType removeFromSuperview];
    }
    if (_delegate) {
        _delegate = nil;
    }

    btnMapType = nil;
    self.mapView = nil;
}


@end
