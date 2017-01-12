//
//  ViewController.m
//  OpenStreetMapTest
//
//  Created by Kanat on 10/01/2017.
//  Copyright © 2017 ak. All rights reserved.
//

#import "ViewController.h"
#import "AKMapMarker.h"
#import "UIView+MKAnnotationView.h"
@import MapKit;


@interface ViewController ()  <MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer* tapGesture;
@property (strong, nonatomic) MKDirections* directions;
@property (strong, nonatomic) NSMutableArray* markersArray;


@end

@implementation ViewController

#pragma mark - Getters

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [CLLocationManager new];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 1;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (NSMutableArray*)markersArray {
    if (!_markersArray) {
        _markersArray = [NSMutableArray array];
    }
    return _markersArray;
}

#pragma mark - View Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.locationManager requestWhenInUseAuthorization];
//    [self.locationManager startUpdatingLocation];
    
    // kkkk
    self.mapView.showsScale = YES;
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.showsTraffic = YES;
    self.mapView.delegate = self;
    
    NSString *template = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    
    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
}


#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer* renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.lineWidth = 4.f;
        renderer.strokeColor = [UIColor colorWithRed:0.f green:0.5f blue:1.f alpha:0.9f];
        return renderer;
    }
    
    return nil;
}


- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    if ([annotation isKindOfClass:[AKMapMarker class]]) {
        static NSString* identifier = @"Annotation";
        
        MKPinAnnotationView* pin =
        (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:identifier];
            pin.pinTintColor = MKPinAnnotationView.purplePinColor;
            pin.animatesDrop = YES;
            pin.canShowCallout = YES;
            pin.draggable = YES;
            
            UIButton* removeMarker = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [removeMarker addTarget:self action:@selector(actionRemoveMarker:)
                   forControlEvents:UIControlEventTouchUpInside];
            pin.rightCalloutAccessoryView = removeMarker;
        } else {
            pin.annotation = annotation;
        }
        
        return pin;
    }
    return nil;
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {

    
}


#pragma mark - Add  Marker

     // Add Marker  by tap
- (IBAction)tapGesture:(UITapGestureRecognizer*)tap {
    
    if ([self.markersArray count] < 10) {
        if (tap.state == UIGestureRecognizerStateRecognized ) {
            
            AKMapMarker* annotation = [[AKMapMarker alloc] init];
            annotation.title = @"Test Title";
            annotation.subtitle = @"Test Subtitle";
            
            // Get coordinates of tap
            CGPoint point = [tap locationInView:tap.view];
            
            CLLocationCoordinate2D pointCoordinate = [self.mapView convertPoint:point
                                                           toCoordinateFromView:tap.view];
            CLLocationCoordinate2D locationCoordinate = annotation.coordinate;
            
            locationCoordinate = pointCoordinate;
            annotation.coordinate = locationCoordinate;
            
            [self.mapView addAnnotation:annotation];
            [self.markersArray addObject:annotation];
            
            // Calculate directions
            MKDirectionsRequest* request = [self createRequesForAnnotation:annotation];
            [self calulateDirectionsWithRequest:request anntotion:annotation];
        }
    } else {
        return;
    }
}


- (MKDirectionsRequest*)createRequesForAnnotation:(AKMapMarker*)annotation {
    
    MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate:annotation.coordinate
                                                   addressDictionary:nil];
    MKDirectionsRequest* request = [[MKDirectionsRequest alloc] init];
    request.destination = [[MKMapItem alloc] initWithPlacemark:placemark];
    
    if ([self.markersArray count] == 1) {
        request.source = [MKMapItem mapItemForCurrentLocation];
    }else {
        NSUInteger index = [self.markersArray indexOfObject:annotation] - 1;
        AKMapMarker* previousAnnotation = [self.markersArray objectAtIndex:index];
        MKPlacemark* previousPlacemark =
        [[MKPlacemark alloc] initWithCoordinate:previousAnnotation.coordinate
                              addressDictionary:nil];
        request.source = [[MKMapItem alloc] initWithPlacemark:previousPlacemark];
    }
    return request;
}


- (void)calulateDirectionsWithRequest:(MKDirectionsRequest*)request anntotion:(AKMapMarker*)annotation {
    
    self.directions = [[MKDirections alloc] initWithRequest:request];
    [self.directions
     calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * response, NSError * error) {
         if (error) {
             NSLog(@"error %@", [error localizedDescription]);
         }
         
         if ([response.routes count] == 0) {
             [self showAlertWithTitle:@"Error" andMessage:@"No routes found"];
         } else {
             
             NSMutableArray* array = [NSMutableArray new];
             for (MKRoute* route in response.routes) {
                 [array addObject:route.polyline];
                 annotation.polyline = route.polyline;
             }
             
             [self.mapView addOverlays:array level:MKOverlayLevelAboveLabels];
         }
     }];
}


#pragma mark - Actions

   // Alert controller
- (void) showAlertWithTitle:(NSString*)title andMessage:(NSString*)message {
     UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}


   // Remove marker and re-built routes
- (void)actionRemoveMarker:(UIButton*) sender {
    MKAnnotationView* annotationView = [sender superAnnotationView];
    
    if (!annotationView) {
        return;
    }
    if ([annotationView.annotation isKindOfClass:[AKMapMarker class]]) {
        AKMapMarker* annotation = (AKMapMarker*)annotationView.annotation;
        [self.mapView removeOverlay:annotation.polyline];
        [self.mapView removeAnnotation:annotationView.annotation];
        NSUInteger index = [self.markersArray indexOfObject:annotation];
        [self.markersArray removeObject:annotation];
        
        if ([self.markersArray count] < index + 1) {
            return;
        }
        AKMapMarker* nextAnnotation = [self.markersArray objectAtIndex:index];
        [self.mapView removeOverlay:nextAnnotation.polyline];
        MKDirectionsRequest* request = [self createRequesForAnnotation:nextAnnotation];
        [self calulateDirectionsWithRequest:request anntotion:nextAnnotation];
    }
    
}


    // Delete All Markers
- (IBAction)deleteAllMarkers:(UIButton*)sender {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.markersArray removeAllObjects];

}


      // Show User Location
- (IBAction)whereIam:(UIButton*)sender {

    if (self.mapView.userLocation) {
        [self.mapView showAnnotations:@[self.mapView.userLocation] animated:YES];
    } else {
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Error"
                                            message:@"Cannot retrieve your current location"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - UIGestureRecognizerDelegate

/*
 
 Put a Polyline on the Map
 
 CLLocationCoordinate2D coordinates[] = {CLLocationCoordinate2DMake(32.7153300, -117.1572600),
 CLLocationCoordinate2DMake(39.7391500, -104.9847000),
 CLLocationCoordinate2DMake(25.7742700, -80.1936600),
 CLLocationCoordinate2DMake(40.7326808, -73.9843407) };
 
 NSUInteger numberOfCoordinates = sizeof(coordinates) / sizeof(CLLocationCoordinate2D);
 
 MGLPolyline *polyline = [MGLPolyline polylineWithCoordinates:coordinates count:numberOfCoordinates];
 
 [self.mapView addAnnotation:polyline];
 
 [self.mapView showAnnotations:@[polyline] animated:YES];
 
 */

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    /*
     let currentLocation = locations.last as CLLocation!
     if (currentLocation!.horizontalAccuracy > 0) {
     // Stop update locations to save battery life
     locationManager.stopUpdatingLocation()
     
     // пердадим наши координаты
     let coords = CLLocationCoordinate2DMake((currentLocation?.coordinate.latitude)!, (currentLocation?.coordinate.longitude)!)
     self.openWeather.weatherFor(geo: coords)
     }
     */
    
    
    //    [self.mapView showAnnotations:@[self.mapView.userLocation] animated:YES];
}




#pragma mark - Memory

- (void)dealloc {
    if ([self.directions isCalculating]) {
        [self.directions cancel];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    UIAlertController* alert =
    [UIAlertController alertControllerWithTitle:@"Warning"
                                        message:@"running out of memory"
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/*
 MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate:annotation.coordinate
 addressDictionary:nil];
 MKDirectionsRequest* request = [[MKDirectionsRequest alloc] init];
 request.destination = [[MKMapItem alloc] initWithPlacemark:placemark];
 
 if ([self.markersArray count] == 1) {
 request.source = [MKMapItem mapItemForCurrentLocation];
 }else {
 NSUInteger index = [self.markersArray indexOfObject:annotation] - 1;
 AKMapMarker* previousAnnotation = [self.markersArray objectAtIndex:index];
 MKPlacemark* previousPlacemark =
 [[MKPlacemark alloc] initWithCoordinate:previousAnnotation.coordinate
 addressDictionary:nil];
 request.source = [[MKMapItem alloc] initWithPlacemark:previousPlacemark];
 }*/

/*
 self.directions = [[MKDirections alloc] initWithRequest:request];
 [self.directions
 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * response, NSError * error) {
 
 if (error) {
 NSLog(@"error %@", [error localizedDescription]);
 }
 
 if ([response.routes count] == 0) {
 [self showAlertWithTitle:@"Error" andMessage:@"No routes found"];
 } else {
 
 NSMutableArray* array = [NSMutableArray new];
 for (MKRoute* route in response.routes) {
 
 [array addObject:route.polyline];
 
 annotation.polyline = route.polyline;
 //[self.markersArray addObject:annotation.polyline];
 }
 
 [self.mapView addOverlays:array level:MKOverlayLevelAboveLabels];
 }
 }]; */





@end
