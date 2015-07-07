//
//  GMSViewController.swift
//  SDKDemos
//
//  Created by SUN Ka Meng Isaac on 22/6/15.
//  Copyright (c) 2015 SUN Ka Meng Isaac. All rights reserved.
//

import UIKit
import GoogleMaps

let MY_LATITUDE: CLLocationDegrees = 22.3383
let MY_LONGITUDE: CLLocationDegrees = 114.171

class GMSMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    // MARK: - Stored Properties
    var loupe: ACLoupe!
    var magnifyingGlass: ACMagnifyingGlass!
    var magnifyingView: ACMagnifyingView!
    var mapView: GMSMapView!
    var mapSubView: GMSMapView!
    var placesClient: GMSPlacesClient?
    var placePicker: GMSPlacePicker?
    var currentPlace: GMSPlace?

    // MARK: - UIView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // AC Magnifying View
        loupe = ACLoupe()
        magnifyingGlass = ACMagnifyingGlass()
        magnifyingView = ACMagnifyingView(frame: self.view.frame)
        magnifyingView.magnifyingGlass = loupe
    
        // MapView
        let cameraPosition = GMSCameraPosition.cameraWithLatitude(MY_LATITUDE, longitude: MY_LONGITUDE, zoom: 15)
        mapView = GMSMapView.mapWithFrame(self.view.frame, camera: cameraPosition)
        mapView.delegate = self
        
        // Places Client
        placesClient = GMSPlacesClient()
        
        magnifyingView.mapView = mapView
        magnifyingView.addSubview(mapView)
        
        self.view = magnifyingView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Place Picker
    
    func getCurrentPlace() {
        placesClient?.currentPlaceWithCallback() { placeLikelihoodList, error in
            if let error = error {
                println("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLicklihoodList = placeLikelihoodList {
                let place = placeLicklihoodList.likelihoods.first?.place
                if let currentPlace = place {
                    println("current Place: \(currentPlace.name)")
                }
            }
        }
    }
    
    func pickPlace() {
        let center = CLLocationCoordinate2DMake(MY_LATITUDE, MY_LONGITUDE)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        placePicker = GMSPlacePicker(config: config)
        
        placePicker?.pickPlaceWithCallback({ (place: GMSPlace?, error) -> Void in
            if let unwrappedError = error {
                println("Pick Place error: \(unwrappedError.localizedDescription)")
                return
            }
            
            if let unwrappedPlace = place {
                println(unwrappedPlace.name)
                println(unwrappedPlace.formattedAddress.componentsSeparatedByString(", "))
            } else {
                println("No place selected")
            }
        })
    }

    // MARK: - IBActions
    
    @IBAction func createSubView(sender: UIBarButtonItem) {
        let roundedCornerImageView = UIImageView(frame: CGRectMake(0, 0, 100, 100))
        roundedCornerImageView.layer.cornerRadius = 20.0
        roundedCornerImageView.clipsToBounds = true
    }

    // MARK: - MapView Delegate Methods

    func mapView(mapView: GMSMapView!, didBeginDraggingMarker marker: GMSMarker!) {
        println("Marker is being dragged")

        
    }
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        println("change position")

    }
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        
        // 1. setting earth coordinate to my place
        let markerPosition = CLLocationCoordinate2DMake(MY_LATITUDE, MY_LONGITUDE)
        let marker = GMSMarker(position: markerPosition)
        marker.title = "FW"
        
        // 2. add the to map
        marker.map = mapView
        
        
    }
    
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {

        let screenCoordinate = mapView.projection.pointForCoordinate(coordinate)
        magnifyingView.addMagnifyingGlassAtPoint(screenCoordinate)
        
    }
    

}

