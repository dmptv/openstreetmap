//
//  AKMapMarker.h
//  OpenStreetMapTest
//
//  Created by Kanat on 10/01/2017.
//  Copyright © 2017 ak. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <MapKit/MKAnnotation.h>
@import MapKit;

@interface AKMapMarker : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@property (strong, nonatomic) MKPolyline* polyline;

@end
