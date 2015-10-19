/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Main view controller for the application.
  Displays the user location along with the path traveled on an MKMapView.
  Implements the MKMapViewDelegate messages for tracking user location and managing overlays.
  
 */

@import UIKit;

@interface BreadcrumbViewController : UIViewController

@property CLLocationCoordinate2D currentLocation;
@property CLLocation *position;

@property (weak, nonatomic) IBOutlet UILabel *Indoors;
@property (weak, nonatomic) IBOutlet UILabel *Outdoors;
@property (weak, nonatomic) IBOutlet UILabel *VerifiedIndoors;
@property (weak, nonatomic) IBOutlet UILabel *Total;
@property (weak, nonatomic) IBOutlet UILabel *Rate;
@property (weak, nonatomic) IBOutlet UILabel *TrackingType;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *Reset;
@end

