//
//  GMSViewController.swift
//  SDKDemos
//
//  Created by SUN Ka Meng Isaac on 22/6/15.
//  Copyright (c) 2015 SUN Ka Meng Isaac. All rights reserved.
//

import UIKit
import Foundation
import GoogleMaps


class GMSMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate, TypesTableViewControllerDelegate {
    // MARK: - IBOutlet
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapCenterPinImage: UIImageView!
    
    // MARK: - Stored Properties
    let MY_LATITUDE: CLLocationDegrees = 22.3383
    let MY_LONGITUDE: CLLocationDegrees = 114.171
    
    var loupe: ACLoupe!
    var magnifyingGlass: ACMagnifyingGlass!
    var magnifyingView: ACMagnifyingView!
    
    var mapView: GMSMapView!
    var routeLine: GMSPolyline?
    var placesClient: GMSPlacesClient?
    var placePicker: GMSPlacePicker?
    var currentPlace: GMSPlace?
    
    var firstContactPoint = CGPoint()
    var draggingContactPoint = CGPoint()

    var currentSelectedMarker: PlaceMarker?
    var markersArray = [PlaceMarker]()
    var markersInBoundArray = [PlaceMarker]()
    
    var locationManager = CLLocationManager()
    var dataProvider = GoogleDataProvider()
    
    var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
    
    var effectiveWidth: CGFloat {
        get {
            return (view.frame.size.width - firstContactPoint.x) / CGFloat(markersInBoundArray.count)
        }
    }
    
    var mapRadius: Double {
        get
        {
            let region = mapView.projection.visibleRegion()
            let verticalDistance = GMSGeometryDistance(region.farLeft, region.nearLeft)
            let horizontalDistance = GMSGeometryDistance(region.farLeft, region.farRight)
            return max(horizontalDistance, verticalDistance) * 0.5
        }
    }
    
    var randomLineColor: UIColor {
        get
        {
            let randRed   = CGFloat(drand48())
            let randGreen = CGFloat(drand48())
            let randBlue  = CGFloat(drand48())
            
            return UIColor(red: randRed, green: randGreen, blue: randBlue, alpha: 1.0)
        }
    }

    // MARK: - UIView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
        // AC Magnifying View
        loupe = ACLoupe()
        magnifyingGlass = ACMagnifyingGlass()
        magnifyingView = ACMagnifyingView(frame: self.view.frame)
        magnifyingView.magnifyingGlass = loupe
    
        // MapView
        let cameraPosition = GMSCameraPosition.cameraWithLatitude(MY_LATITUDE, longitude: MY_LONGITUDE, zoom: 15)
        mapView = GMSMapView.mapWithFrame(self.view.frame, camera: cameraPosition)
        mapView.delegate = self
        mapView.myLocationEnabled = true
        mapView.settings.consumesGesturesInView = false
        
        // Places Client
        placesClient = GMSPlacesClient()
        
        magnifyingView.mapView = mapView
        magnifyingView.addSubview(mapView)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        mapView.addGestureRecognizer(longPressGesture)
        
        self.view = magnifyingView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.toolbarHidden = false
        let barHeight = self.navigationController?.navigationBar.intrinsicContentSize().height
        self.mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: barHeight!, right: 0)
    }
    
    // MARK: - @IBAction functions
    

    
    @IBAction func refreshPlaces(sender: AnyObject) {
        fetchNearbyPlaces(mapView.camera.target)
    }
    
    @IBAction func didTapClear() { mapView.clear() }
    
    // MARK: - Helper Functions
    func didTapMyLocationButtonForMapView(mapView: GMSMapView!) -> Bool {
        mapView.selectedMarker = nil
        routeLine?.map = nil
        return false
    }
    
    func selectMarkersInBound(radius: CGFloat) {
        markersInBoundArray.removeAll(keepCapacity: true)
        for marker in markersArray {
            if ( isInBound(mapView.projection.pointForCoordinate(marker.position)) ) {
                markersInBoundArray.append(marker)
            }
        }
    }
    
    func isInBound(point: CGPoint ) -> Bool {
        if ( point.x >= firstContactPoint.x &&
            point.x < view.frame.width &&
            point.y > 0 &&
            point.y < view.frame.height ) {
                return true
        }
        return false
    }
    
    func sortByXcoordinate() {
        markersInBoundArray.sort() {
            self.mapView.projection.pointForCoordinate($0.position).x < self.mapView.projection.pointForCoordinate($1.position).x
        }
    }
    
    func dist(touchPoint: CGPoint, target: CGPoint) -> CGFloat {
        let xDiff = abs(target.x - touchPoint.x)
        let yDiff = abs(target.y - touchPoint.y)
        
        return sqrt(xDiff*xDiff + yDiff*yDiff)
    }
    
    // MARK: - CLLocationManager Delegate Methods
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // 2
        if status == .AuthorizedWhenInUse {
            // 3
            locationManager.startUpdatingLocation()
        }
    }
    
    // 5 - 8
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            locationManager.stopUpdatingLocation()
            fetchNearbyPlaces(location.coordinate)
        }
    }
    
    // MARK: - Types Controller Delegate
    func typesController(controller: TypesTableViewController, didSelectTypes types: [String]) {
        searchedTypes = sorted(controller.selectedTypes)
        // 9
        if (!searchedTypes.isEmpty) {
            fetchNearbyPlaces(mapView.camera.target)
        }
        else {
            mapView.clear()
            markersArray.removeAll(keepCapacity: true)
            markersInBoundArray.removeAll(keepCapacity: true)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
 

    // MARK: - GMSMapView Delegate Methods
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        if let marker = currentSelectedMarker {
            marker.icon = UIImage(named: marker.place.placeType + "_pin")
        }
    }
    
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {
        mapView.settings.setAllGesturesEnabled(false)
        firstContactPoint = mapView.projection.pointForCoordinate(coordinate)
        magnifyingView.addMagnifyingGlassAtPoint(firstContactPoint)
    }
 
    func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {
        if let placeMarker = marker as? PlaceMarker {
            currentSelectedMarker = placeMarker
            
            if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
                infoView.nameLabel.text = placeMarker.place.name
                
                if let photo = placeMarker.place.photo {
                    infoView.placePhoto.image = photo
                }
                else {
                    infoView.placePhoto.image = UIImage(named: "generic")
                }
                
                return infoView
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        routeLine?.map = nil
        return false
    }
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        routeLine?.map = nil
        // 1
        if let googleMarker = mapView.selectedMarker as? PlaceMarker {
            googleMarker.icon = UIImage(named: googleMarker.place.placeType + "_pin")

            // 2
            dataProvider.fetchDirectionsFrom(mapView.myLocation.coordinate, to: googleMarker.place.coordinate ) { optionalRoute in
                if let encodedRoute = optionalRoute
                {
                    // 3
                    let path = GMSPath(fromEncodedPath: encodedRoute)
                    self.routeLine = GMSPolyline(path: path)
                    // 4
                    self.routeLine!.strokeWidth = 4.0
                    self.routeLine!.tappable    = true
                    self.routeLine!.map         = self.mapView
                    self.routeLine!.strokeColor = self.randomLineColor
                    self.routeLine!.geodesic    = true
                }
            }
        }
    }
    
    // Gesture Recognizer
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Began) {
            selectMarkersInBound(self.view.frame.width)
            if ( !markersInBoundArray.isEmpty ) {
                sortByXcoordinate()
            }

        }
        else if (recognizer.state == UIGestureRecognizerState.Changed) {

            if (magnifyingView.getIsShown() && !markersInBoundArray.isEmpty ) {
                draggingContactPoint = recognizer.locationInView(self.view)
                var kIndex = 0
                if (draggingContactPoint.x >= firstContactPoint.x) {
                    kIndex = Int(dist(firstContactPoint, target: draggingContactPoint) / effectiveWidth)
                }
                if ( currentSelectedMarker != nil ) {
                    currentSelectedMarker!.icon = UIImage(named: currentSelectedMarker!.place.placeType + "_pin")
                }
                currentSelectedMarker = markersInBoundArray[safe:kIndex]
                if ( currentSelectedMarker != nil) {
                    currentSelectedMarker?.icon = UIImage(named: currentSelectedMarker!.place.placeType + "_pin_selected")
                    magnifyingView.addMagnifyingGlassAtPoint(mapView.projection.pointForCoordinate(currentSelectedMarker!.position))
                }
            }
        }
        else if (recognizer.state == UIGestureRecognizerState.Ended) {
            if (magnifyingView.getIsShown()) {
                mapView.settings.setAllGesturesEnabled(true)
                magnifyingView.removeMagnifyingGlass()

                if ( currentSelectedMarker != nil ) {
                    mapView.selectedMarker = currentSelectedMarker
                    mapView(mapView, didTapInfoWindowOfMarker: currentSelectedMarker)
                }
            }
        }
        
    }
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        dataProvider.fetchPlacesNearCoordinate(coordinate, radius: mapRadius, types: searchedTypes) { places in
            self.mapView.clear()
            for place: GooglePlace in places {
                let marker = PlaceMarker(place: place)
                marker.map = self.mapView
                self.markersArray.append(marker)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Types Segue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = segue.destinationViewController.topViewController as! TypesTableViewController
            controller.selectedTypes = searchedTypes
            controller.delegate = self
        }
    }
    
}

extension Array {
    subscript (safe index: Int) -> T? {
        return indices(self) ~= index ? self[index] : nil
    }
}

