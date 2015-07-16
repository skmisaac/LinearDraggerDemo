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
    @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!
    
    // MARK: - Stored Properties
    let MY_LATITUDE: CLLocationDegrees = 22.3383
    let MY_LONGITUDE: CLLocationDegrees = 114.171
    let minDistance = 100.0
    
    var loupe: ACLoupe!
    var magnifyingGlass: ACMagnifyingGlass!
    var magnifyingView: ACMagnifyingView!
    
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient?
    var placePicker: GMSPlacePicker?
    var currentPlace: GMSPlace?
    
    var firstContactPoint = CGPoint()
    var draggingContactPoint = CGPoint()
    var effectiveWidth: CGFloat = 0.0
    
    var selectedMarker: GMSMarker?
    var markersArray = [GMSMarker]()
    var markersInAreaArray = [GMSMarker]()
    
    var locationManager = CLLocationManager()
    var dataProvider = GoogleDataProvider()
    
    var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
    
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
        
        // Set Gesture Recognizer
        
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
    }
    
    // MARK: - Helper functions
    
    @IBAction func didTapAddMarker() {
        for i in 1...10 {
            var delayInSeconds = Double(i) * 0.25
            let popTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, (Int64)(delayInSeconds * Double(NSEC_PER_SEC)) )
            dispatch_after(popTime, dispatch_get_main_queue()) {
                let region: GMSVisibleRegion = self.mapView.projection.visibleRegion()
                let bounds: GMSCoordinateBounds = GMSCoordinateBounds(region: region)
                self.addMarkerInBounds(bounds)
            }
        }
    }
    
    @IBAction func didTapClear() {
        mapView.clear()
    }

    func randomZeroToOne() -> Double {
        return Double(arc4random()) / Double(UInt32.max)
    }
    
    func addMarkerInBounds(bounds: GMSCoordinateBounds) {
        var latitude: CLLocationDegrees = bounds.southWest.latitude + randomZeroToOne() * (bounds.northEast.latitude - bounds.southWest.latitude)
        var offset = (bounds.northEast.longitude < bounds.southWest.longitude)
        var longitude: CLLocationDegrees = bounds.southWest.longitude + randomZeroToOne() * (bounds.northEast.longitude - bounds.southWest.longitude + (offset ? 360 : 0))
        
        if (longitude > 180.0) {
            longitude -= 360.0
        }
        
        let color = UIColor(hue: CGFloat(randomZeroToOne()), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let randomCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        var marker = GMSMarker(position: randomCoordinate)
        marker.title = "Default"
        marker.snippet = "Default Info"
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.icon = GMSMarker.markerImageWithColor(color)
        marker.map = mapView
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
            // 4
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
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
 

    // MARK: - GMSMapView Delegate Methods
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        reverseGeocodeCoordinate(position.target)
    }

    func mapView(mapView: GMSMapView!, didBeginDraggingMarker marker: GMSMarker!) {
        println("mapView(_: didBeginDraggingMarker: ")
    }
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        let marker = GMSMarker(position: coordinate)
        marker.title = "Default"
        marker.map = mapView
        markersArray.append(marker)
    }
    
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {
        mapView.settings.setAllGesturesEnabled(false)
        firstContactPoint = mapView.projection.pointForCoordinate(coordinate)
        magnifyingView.addMagnifyingGlassAtPoint(firstContactPoint)
    }
    
    
    func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {
        // 1
        let placeMarker = marker as! PlaceMarker
        
        var placeXY = mapView.projection.pointForCoordinate(placeMarker.position)
        
        
        // 2
        if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
            infoView.nameLabel.text = placeMarker.place.name
            
            //4
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
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        // 1
        let googleMarker = mapView.selectedMarker as! PlaceMarker
        
        // 2
        dataProvider.fetchDirectionsFrom(mapView.myLocation.coordinate, to: googleMarker.place.coordinate ) { optionalRoute in
            if let encodedRoute = optionalRoute
            {
                // 3
                let path = GMSPath(fromEncodedPath: encodedRoute)
                let line = GMSPolyline(path: path)
                
                // 4
                line.strokeWidth = 4.0
                line.tappable    = true
                line.map         = self.mapView
                line.strokeColor = self.randomLineColor
                
                // 5
                mapView.selectedMarker = nil
            }
        }
    }
    
    // MARK: - Helper Functions
    func didTapMyLocationButtonForMapView(mapView: GMSMapView!) -> Bool {
        mapView.selectedMarker = nil
        return false
    }
    
    func selectMarkersInBound(radius: CGFloat) {
        for marker in markersArray {
            if ( isInBound(mapView.projection.pointForCoordinate(marker.position), radius: radius) ) {
                markersInAreaArray.append(marker)
            }
        }
    }
    
    func isInBound(point: CGPoint, radius: CGFloat) -> Bool {
        if ( point.x > firstContactPoint.x + radius ) {
            return false
        }
        if ( point.x < firstContactPoint.x - radius ) {
            return false
        }
        if ( point.y > firstContactPoint.y + radius ) {
            return false
        }
        if ( point.y < firstContactPoint.y - radius ) {
            return false
        }
        println("is in bound")
        return true
    }
    
    func getEffectiveWidth() -> CGFloat {
        println("getEffectiveWidth reached")
        return (view.frame.size.width - draggingContactPoint.x) * 0.8
    }
    
    func sortByXcoordinate() {
        markersInAreaArray.sort() {
            self.mapView.projection.pointForCoordinate($0.position).x < self.mapView.projection.pointForCoordinate($1.position).x
        }
    }
    
    // Gesture Recognizer
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Began) {
            println("UIGestureRecognizer: began")
            selectMarkersInBound(self.view.frame.width)
            if ( markersInAreaArray.isEmpty ) {
                println("markersInAreaArray cannot select Markers InBound")
            }
            else {
                effectiveWidth = getEffectiveWidth() / CGFloat(markersInAreaArray.count)
                sortByXcoordinate()
            }
        }
        else if (recognizer.state == UIGestureRecognizerState.Changed) {
            if (magnifyingView.getIsShown()) {
                println("UIGestureRecognizer: changed")
            
                effectiveWidth = getEffectiveWidth()
                draggingContactPoint = recognizer.locationInView(self.view)
                var kIndex = Int(dist(firstContactPoint, target: draggingContactPoint) / effectiveWidth)
                selectedMarker = markersInAreaArray[safe: kIndex]
                magnifyingView.addMagnifyingGlassAtPoint(mapView.projection.pointForCoordinate(selectedMarker!.position))
            }
        }
        else if (recognizer.state == UIGestureRecognizerState.Ended) {
            if (magnifyingView.getIsShown()) {
                println ("UIGestureRecognizer: ended")
                mapView.settings.setAllGesturesEnabled(true)
                magnifyingView.removeMagnifyingGlass()
                mapView.selectedMarker = selectedMarker
                if ( !markersInAreaArray.isEmpty ) {
                    markersInAreaArray.removeAll(keepCapacity: true)
                }
                if ( !markersArray.isEmpty ) {
                    markersArray.removeAll(keepCapacity: true)
                }
            }
        }
        
    }
    
    @IBAction func refreshPlaces(sender: AnyObject) {
        fetchNearbyPlaces(mapView.camera.target)
    }
    
    @IBAction func mapTypeSegmentPressed(sender: AnyObject) {
        let segmentedControl = sender as! UISegmentedControl
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            mapView.mapType = kGMSTypeNormal
        case 1:
            mapView.mapType = kGMSTypeSatellite
        case 2:
            mapView.mapType = kGMSTypeHybrid
        default:
            mapView.mapType = mapView.mapType
        }
    }
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        // 1
        mapView.clear()
        
        dataProvider.fetchPlacesNearCoordinate(coordinate, radius: mapRadius, types: searchedTypes) { places in
            for place: GooglePlace in places {
                let marker = PlaceMarker(place: place)
                marker.map = self.mapView
                self.markersArray.append(marker)
            }
        }
    }
    
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
        // 1
        // let geocoder = GMSGeocoder()
        /*
        // 2
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            if let address = response?.firstResult() {
                
                self.addressLabel.unlock()
                // 3
                let lines = address.lines as! [String]
                self.addressLabel.text = join("\n", lines)
                
                // 4-1
                let labelHeight = self.addressLabel.intrinsicContentSize().height
                self.mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: labelHeight, right: 0)
                
                //4
                UIView.animateWithDuration(0.25) {
                    // 4-2
                    // update locaion pin's position to match map's padding by adjusting its vertical layout constraint
                    self.pinImageVerticalConstraint.constant = ((labelHeight - self.topLayoutGuide.length) * 0.5)
                    self.view.layoutIfNeeded()
                }
            }
        }*/
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Types Segue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = segue.destinationViewController.topViewController as! TypesTableViewController
            controller.selectedTypes = searchedTypes
            controller.delegate = self
        }
    }
    
    // MARK: - Types Controller Delegate
    func typesController(controller: TypesTableViewController, didSelectTypes types: [String]) {
        searchedTypes = sorted(controller.selectedTypes)
        // 9
        fetchNearbyPlaces(mapView.camera.target)
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension Array {
    subscript (safe index: Int) -> T? {
        return indices(self) ~= index ? self[index] : nil
    }
}

