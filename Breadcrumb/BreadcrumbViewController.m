/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "CrumbPath.h"
#import "CrumbPathRenderer.h"
#import "BreadcrumbViewController.h"
#import "SettingsKeys.h"
#import <parkour/parkour.h>

@import AVFoundation;       // for AVAudioSession

#define kDebugShowArea 1    // for debugging purposes, draw the map polygon area in which the breacrumbs path is drawn
#define MAP_DISPLAY_SCALE 0.5 * 1609.344

@interface BreadcrumbViewController() <MKMapViewDelegate, AVAudioPlayerDelegate>

// removed CLLocationManagerDelegate

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) CrumbPath *crumbs;
@property (nonatomic, strong) CrumbPathRenderer *crumbPathRenderer;
@property (nonatomic, strong) MKPolygonRenderer *drawingAreaRenderer;   // shown if kDebugShowArea is set to 1

@property (nonatomic, weak) IBOutlet MKMapView *map;
@property (nonatomic) double Ind;
@property (nonatomic) double Out;
@property (nonatomic) double Vin;
@property (nonatomic) double Tot;
@property (nonatomic) double Rat;
@property (nonatomic) bool FirstRun;
@property (nonatomic, strong) NSDate *startdate;

//@property (nonatomic, strong) CLLocationManager *locationManager;

//@property CLLocationCoordinate2D currentLocation;
//@property CLLocation *position;

@end


#pragma mark -

@implementation BreadcrumbViewController
- (IBAction)Reset:(id)sender {
    
     _startdate = [NSDate date];
    _Ind = 0; // _Ind +1;
    _Out = 0; //_Out +1;
    _Vin = 0; //_Vin +1;
    _Tot = 0; //_Tot + 1;
    double blah = 0;
    self.Indoors.text = [NSString stringWithFormat:@"Ind: %.0f",blah];
    self.Outdoors.text = [NSString stringWithFormat:@"Out: %.0f",blah];
    self.VerifiedIndoors.text = [NSString stringWithFormat:@"Vin: %.0f",blah];
    self.Total.text = [NSString stringWithFormat:@"Tot: %.0f",blah];
    self.Rate.text = [NSString stringWithFormat:@"Rate/s: %.1f",blah];

    

}




// called for NSUserDefaultsDidChangeNotification
- (void)settingsDidChange:(NSNotification *)notification
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    
    // update our location manager for these settings changes:
    
    // accuracy (CLLocationAccuracy)
//    CLLocationAccuracy desiredAccuracy = [settings doubleForKey:LocationTrackingAccuracyPrefsKey];
//    self.locationManager.desiredAccuracy = desiredAccuracy;
    
    [parkour setTrackPositionMode:[settings doubleForKey:LocationTrackingAccuracyPrefsKey]];
    
    NSString *positionmode = @"nada";

    int themode = [settings doubleForKey:LocationTrackingAccuracyPrefsKey];
    switch (themode) {
        case 0:
            positionmode = @"LowEnergy 120";
            break;
        case 1:
            positionmode = @"Geofencing 60";
            break;
        case 2:
            positionmode = @"Pedestrian 10";
            break;
        case 3:
            positionmode = @"Fitness 7";
            break;
        case 4:
            positionmode = @"Automotive 5";
            break;
        case 5:
            positionmode = @"Share 45";
            break;
        default:
            positionmode = @"Default";
    }

    
    self.TrackingType.text = [NSString stringWithFormat:@"%@",positionmode];

    // note:
    // for "PlaySoundOnLocationUpdatePrefsKey", code to play the sound later will read this default value
    // for "TrackLocationInBackgroundPrefsKey", code to track location in background will read this default value
}


#pragma mark - View Layout

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Corrected spelling on "initilizeAudioPlayer"

    if (!_FirstRun) {
    _startdate = [NSDate date];
        _FirstRun = TRUE;
    }

    [self initializeAudioPlayer];
//    [self initilizeLocationTracking];
    [self initializeTrackingAndConfigureMap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    // allow the user to change the tracking mode on the map view by placing this button in the navigation bar
//    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.map];
//    self.navigationItem.leftBarButtonItem = userTrackingButton;
}

- (void)dealloc
{
    // even though we are using ARC we still need to:
    
    // 1) properly balance the unregister from the NSNotificationCenter,
    // which was registered previously in "viewDidLoad"
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 2) manually unregister for delegate callbacks,
    // As of iOS 7, most system objects still use __unsafe_unretained delegates for compatibility.
    //
//    self.locationManager.delegate = nil;
    self.audioPlayer.delegate = nil;
}


#pragma mark - Location Tracking

//- (void)initilizeLocationTracking
//{
//    _locationManager = [[CLLocationManager alloc] init];
//    assert(self.locationManager);
//    
//    self.locationManager.delegate = self; // tells the location manager to send updates to this object
    
//    iOS 8 introduced a more powerful privacy model: <https://developer.apple.com/videos/wwdc/2014/?id=706>.
//     We use -respondsToSelector: to only call the new authorization API on systems that support it.
    
//    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
//    {
//        [self.locationManager requestWhenInUseAuthorization];
    
        // note: doing so will provide the blue status bar indicating iOS
        // will be tracking your location, when this sample is backgrounded
//    }
    
//     By default we use the best accuracy setting (kCLLocationAccuracyBest)
//	
//	 You may instead want to use kCLLocationAccuracyBestForNavigation, which is the highest possible
//	 accuracy and combine it with additional sensor data.  Note that level of accuracy is intended
//	 for use in navigation applications that require precise position information at all times and
//	 are intended to be used only while the device is plugged in.
    
	


    // start tracking the user's location
//    [self.locationManager startUpdatingLocation];
    
    // Observe the application going in and out of the background, so we can toggle location tracking.
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleUIApplicationDidEnterBackgroundNotification:)
//                                                 name:UIApplicationDidEnterBackgroundNotification
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleUIApplicationWillEnterForegroundNotification:)
//                                                 name:UIApplicationWillEnterForegroundNotification
//                                               object:nil];
//}

//- (void)handleUIApplicationDidEnterBackgroundNotification:(NSNotification *)note
//{
//    [self switchToBackgroundMode:YES];
//}
//
//- (void)handleUIApplicationWillEnterForegroundNotification :(NSNotification *)note
//{
//    [self switchToBackgroundMode:NO];
//}
//
//// called when the app is moved to the background (user presses the home button) or to the foreground
////
//- (void)switchToBackgroundMode:(BOOL)background
//{
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:TrackLocationInBackgroundPrefsKey])
//    {
//        return; // nothing to do, just keep tracking location
//    }
//    
//    if (background)
//    {
//        [self.locationManager stopUpdatingLocation];
//    }
//    else
//    {
//        [self.locationManager startUpdatingLocation];
//    }
    
    
    
    
    
//}

- (MKCoordinateRegion)coordinateRegionWithCenter:(CLLocationCoordinate2D)centerCoordinate approximateRadiusInMeters:(CLLocationDistance)radiusInMeters
{
    // Multiplying by MKMapPointsPerMeterAtLatitude at the center is only approximate, since latitude isn't fixed
    //
    double radiusInMapPoints = radiusInMeters*MKMapPointsPerMeterAtLatitude(centerCoordinate.latitude);
    MKMapSize radiusSquared = {radiusInMapPoints,radiusInMapPoints};
    
    MKMapPoint regionOrigin = MKMapPointForCoordinate(centerCoordinate);
    MKMapRect regionRect = (MKMapRect){regionOrigin, radiusSquared}; //origin is the top-left corner
    
    regionRect = MKMapRectOffset(regionRect, -radiusInMapPoints/2, -radiusInMapPoints/2);
    
    // clamp the rect to be within the world
    regionRect = MKMapRectIntersection(regionRect, MKMapRectWorld);
    
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(regionRect);
    return region;
}


//- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
//{
//    if (locations != nil && locations.count > 0)
//    {
- (void)initializeTrackingAndConfigureMap
{
    [parkour setTrackPositionMode:[[NSUserDefaults standardUserDefaults] doubleForKey:LocationTrackingAccuracyPrefsKey]];
    [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType)
     {
         if (positionType == pkIndoors) _Ind = _Ind +1;
         if (positionType == pkOutdoors) _Out = _Out +1;
         if (positionType == pkVerifiedIndoors) _Vin = _Vin +1;
         _Tot = _Tot + 1;

         self.Indoors.text = [NSString stringWithFormat:@"Ind: %.0f",_Ind];
         self.Outdoors.text = [NSString stringWithFormat:@"Out: %.0f",_Out];
         self.VerifiedIndoors.text = [NSString stringWithFormat:@"Vin: %.0f",_Vin];
         self.Total.text = [NSString stringWithFormat:@"Tot: %.0f",_Tot];
         double elapsed = fabs( [_startdate timeIntervalSince1970] - [[NSDate date] timeIntervalSince1970]);
      //   NSLog(@"elapased: %f",elapsed);
         
         self.Rate.text = [NSString stringWithFormat:@"Rate/s: %.1f",(_Tot/elapsed)];

         
         
//         NSLog(@"tracking lat %f and lng %f", position.coordinate.latitude, position.coordinate.longitude);
         NSLog(@"You are currently %ld", (long)motionType);
         self.currentLocation = position.coordinate;
         self.position = position;
     
        if ([[NSUserDefaults standardUserDefaults] boolForKey:PlaySoundOnLocationUpdatePrefsKey])
        {
            [self setSessionActiveWithMixing:YES]; // YES == duck if other audio is playing
            [self playSound];
        }
        
        // we are not using deferred location updates, so always use the latest location
//        CLLocation *newLocation = locations[0];
    
        if (self.crumbs == nil)
        {
            // This is the first time we're getting a location update, so create
            // the CrumbPath and add it to the map.
            //
            _crumbs = [[CrumbPath alloc] initWithCenterCoordinate:position.coordinate];
            [self.map addOverlay:self.crumbs level:MKOverlayLevelAboveRoads];
            
            // on the first location update only, zoom map to user location
//            CLLocationCoordinate2D newCoordinate = newLocation.coordinate;
            
            // default -boundingMapRect size is 1km^2 centered on coord
            MKCoordinateRegion region = [self coordinateRegionWithCenter:position.coordinate approximateRadiusInMeters:2500];
            
            [self.map setRegion:region animated:YES];
        }
        else
        {
            // This is a subsequent location update.
            //
            // If the crumbs MKOverlay model object determines that the current location has moved
            // far enough from the previous location, use the returned updateRect to redraw just
            // the changed area.
            //
            // note: cell-based devices will locate you using the triangulation of the cell towers.
            // so you may experience spikes in location data (in small time intervals)
            // due to cell tower triangulation.
            //
            BOOL boundingMapRectChanged = NO;
            MKMapRect updateRect = [self.crumbs addCoordinate:position.coordinate boundingMapRectChanged:&boundingMapRectChanged];
            if (boundingMapRectChanged && motionType == pkOutdoors)
            {
                // MKMapView expects an overlay's boundingMapRect to never change (it's a readonly @property).
                // So for the MapView to recognize the overlay's size has changed, we remove it, then add it again.
                [self.map removeOverlays:self.map.overlays];
                _crumbPathRenderer = nil;
                [self.map addOverlay:self.crumbs level:MKOverlayLevelAboveRoads];
                
    //            MKMapRect r = self.crumbs.boundingMapRect;
    //            MKMapPoint pts[] = {
    //                MKMapPointMake(MKMapRectGetMinX(r), MKMapRectGetMinY(r)),
    //                MKMapPointMake(MKMapRectGetMinX(r), MKMapRectGetMaxY(r)),
    //                MKMapPointMake(MKMapRectGetMaxX(r), MKMapRectGetMaxY(r)),
    //                MKMapPointMake(MKMapRectGetMaxX(r), MKMapRectGetMinY(r)),
    //            };
    //            NSUInteger count = sizeof(pts) / sizeof(pts[0]);
    //            MKPolygon *boundingMapRectOverlay = [MKPolygon polygonWithPoints:pts count:count];
    //            [self.map addOverlay:boundingMapRectOverlay level:MKOverlayLevelAboveRoads];
            }
            else if (!MKMapRectIsNull(updateRect))
            {
                // There is a non null update rect.
                // Compute the currently visible map zoom scale
                MKZoomScale currentZoomScale = (CGFloat)(self.map.bounds.size.width / self.map.visibleMapRect.size.width);
                // Find out the line width at this zoom scale and outset the updateRect by that amount
                CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                // Ask the overlay view to update just the changed area.
                [self.crumbPathRenderer setNeedsDisplayInMapRect:updateRect];
            }
          }
         [parkour trackPOIWithHandler:^(NSString *POIName, NSString *categoryOne, NSString *categoryTwo, NSString *fullAddress, NSString *city, NSString *state, NSString *zipcode, CLLocation *POIPosition, CLLocation *userPosition, double distance)
          {
              NSLog(@"Tracking Points of Intrest: POIName %@, categoryOne %@, categoryTwo %@, fullAddress %@, city %@, state %@, zipcode %@, POIPosition %@, userPosition %@, distance %f", POIName, categoryOne, categoryTwo, fullAddress, city, state, zipcode, POIPosition, userPosition, distance);
              
//              MKPinAnnotationView *parkourPin = [self returnPointView:position.coordinate andTitle:[NSString stringWithFormat:@"%@",fullAddress] andsubtitle:[NSString stringWithFormat:@"%@",categoryOne] andColor:MKPinAnnotationColorPurple];
              MKPointAnnotation *parkourPin = [[MKPointAnnotation alloc] init];
              parkourPin.coordinate = POIPosition.coordinate;
              parkourPin.title = [NSString stringWithFormat:@"%@ %@",POIName, categoryTwo];
              parkourPin.subtitle = [NSString stringWithFormat:@"%@",fullAddress];
              
              [self.map addAnnotation:parkourPin];
          }];
        }];

}

//-(MKPinAnnotationView*) returnPointView:(CLLocationCoordinate2D) location2D andTitle:(NSString*) title andsubtitle:(NSString*) subtitle andColor: (int) color
//{
//    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
//    MKPinAnnotationView *pinAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:pointAnnotation reuseIdentifier:nil];
//    [pointAnnotation setCoordinate:location2D];
//    pointAnnotation.title = title;
//    pointAnnotation.subtitle = subtitle;
//    pinAnnotation.pinColor = color;
//    
//    return pinAnnotation;
//}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!pinView)
        {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
            pinView.pinColor = MKPinAnnotationColorGreen;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

//    }
//}

//- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
//{
//    NSLog(@"%s:%d %@", __func__, __LINE__, error);
//}

//static NSString *DescriptionOfCLAuthorizationStatus(CLAuthorizationStatus st)
//{
//    switch (st)
//    {
//        case kCLAuthorizationStatusNotDetermined:
//            return @"kCLAuthorizationStatusNotDetermined";
//        case kCLAuthorizationStatusRestricted:
//            return @"kCLAuthorizationStatusRestricted";
//        case kCLAuthorizationStatusDenied:
//            return @"kCLAuthorizationStatusDenied";
//        //case kCLAuthorizationStatusAuthorized: is the same as
//        //kCLAuthorizationStatusAuthorizedAlways
//        case kCLAuthorizationStatusAuthorizedAlways:
//            return @"kCLAuthorizationStatusAuthorizedAlways";
//            
//        case kCLAuthorizationStatusAuthorizedWhenInUse:
//            return @"kCLAuthorizationStatusAuthorizedWhenInUse";
//    }
//    return [NSString stringWithFormat:@"Unknown CLAuthorizationStatus value: %d", st];
//}

//- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
//{
//    NSLog(@"%s:%d %@", __func__, __LINE__, DescriptionOfCLAuthorizationStatus(status));
//}


#pragma mark - MapKit

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    MKOverlayRenderer *renderer = nil;
    
    if ([overlay isKindOfClass:[CrumbPath class]])
    {
        if (self.crumbPathRenderer == nil)
        {
            _crumbPathRenderer = [[CrumbPathRenderer alloc] initWithOverlay:overlay];
        }
        renderer = self.crumbPathRenderer;
    }
    else if ([overlay isKindOfClass:[MKPolygon class]])
    {
#if kDebugShowArea
        if (![self.drawingAreaRenderer.polygon isEqual:overlay])
        {
            _drawingAreaRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
            self.drawingAreaRenderer.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.25];
        }
        renderer = self.drawingAreaRenderer;
#endif
    }
    
    return renderer;
}


#pragma mark - Audio Support

- (void)initializeAudioPlayer
{
	// set our default audio session state
	[self setSessionActiveWithMixing:NO];
	
    NSURL *heroSoundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Hero" ofType:@"aiff"]];
    assert(heroSoundURL);
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:heroSoundURL error:nil];
}

- (void)setSessionActiveWithMixing:(BOOL)duckIfOtherAudioIsPlaying
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];

    if ([[AVAudioSession sharedInstance] isOtherAudioPlaying] && duckIfOtherAudioIsPlaying)
    {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:nil];
    }

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)playSound
{
    assert(self.audioPlayer);
	if (self.audioPlayer && (self.audioPlayer.isPlaying == NO))
    {
		[self.audioPlayer prepareToPlay];
		[self.audioPlayer play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

@end
