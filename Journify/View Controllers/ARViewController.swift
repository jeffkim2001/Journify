//
//  ARViewController.swift
//  Journify
//
//  Created by Jeff Kim on 10/20/18.
//  Copyright © 2018 Jeff Kim. All rights reserved.
//

import UIKit
import SceneKit
import MapKit
import ARCL
import CoreLocation
import Firebase

@available(iOS 11.0, *)
class ARViewController: UIViewController {
    @IBOutlet weak var sceneLocationView: SceneLocationView!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var addEventButton: UIButton!
    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?
    var locationManager = CLLocationManager()
    var updateUserLocationTimer: Timer?
    var currentLocation: CLLocation!
    var tappedNode: LocationAnnotationNode!
    var currentUser: String = ""
    @IBOutlet weak var profileButton: UIButton!
    
    ///Whether to show a map view
    ///The initial value is respected
    var showMapView: Bool = false
    
    var centerMapOnUserLocation: Bool = true
    
    ///Whether to display some debugging data
    ///This currently displays the coordinate of the best location estimate
    ///The initial value is respected
    var displayDebugging = false
    
    var infoLabel = UILabel()
    
    var updateInfoLabelTimer: Timer?
    
    var adjustNorthByTappingSidesOfScreen = false
    
    var allAnnotations: [String: [LocationAnnotationNode]] = [:]
    var nodes: [LocationAnnotationNode] = []
    
    @objc func updateAnnotations(_ notification: NSNotification) {
        if let annotations = notification.userInfo?["annotations"] as? [String:[LocationAnnotationNode]] {
            allAnnotations = annotations
        }
        if let userNodes = allAnnotations[currentUser] {
            nodes = userNodes
            print("AA", nodes)
            for index in 0..<nodes.count {
                let annotationNode = LocationAnnotationNode(location: nodes[index].location, image: nodes[index].image, date: nodes[index].date)
                annotationNode.scaleRelativeToDistance = true
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = (Auth.auth().currentUser?.email)!
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAnnotations(_:)), name: Notification.Name(rawValue: "transferAnnotations"), object: nil)
        logOutButton.layer.cornerRadius = 5.0
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        addEventButton.alpha = 1
        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        updateInfoLabelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(ARViewController.updateInfoLabel),
            userInfo: nil,
            repeats: true)
        
        // Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
                sceneLocationView.orientToTrueNorth = false
        
        //        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.locationDelegate = self
        
        if displayDebugging {
            sceneLocationView.showFeaturePoints = true
        }
        if showMapView {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.alpha = 0.8
            view.addSubview(mapView)
            
            updateUserLocationTimer = Timer.scheduledTimer(
                timeInterval: 0.5,
                target: self,
                selector: #selector(ARViewController.updateUserLocation),
                userInfo: nil,
                repeats: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("run")
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("pause")
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        infoLabel.frame = CGRect(x: 6, y: 0, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        if showMapView {
            infoLabel.frame.origin.y = (self.view.frame.size.height / 2) - infoLabel.frame.size.height
        } else {
            infoLabel.frame.origin.y = self.view.frame.size.height - infoLabel.frame.size.height
        }
        
        mapView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 2,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
    }
    
    @objc func updateUserLocation() {
        guard let currentLocation = sceneLocationView.currentLocation() else {
            return
        }
        
        DispatchQueue.main.async {
            if let bestEstimate = self.sceneLocationView.bestLocationEstimate(),
                let position = self.sceneLocationView.currentScenePosition() {
                print("")
                print("Fetch current location")
                print("best location estimate, position: \(bestEstimate.position), location: \(bestEstimate.location.coordinate), accuracy: \(bestEstimate.location.horizontalAccuracy), date: \(bestEstimate.location.timestamp)")
                print("current position: \(position)")
                
                let translation = bestEstimate.translatedLocation(to: position)
                
                print("translation: \(translation)")
                print("translated location: \(currentLocation)")
                print("")
            }
            
            if self.userAnnotation == nil {
                self.userAnnotation = MKPointAnnotation()
                self.mapView.addAnnotation(self.userAnnotation!)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.allowUserInteraction, animations: {
                self.userAnnotation?.coordinate = currentLocation.coordinate
            }, completion: nil)
            
            if self.centerMapOnUserLocation {
                UIView.animate(withDuration: 0.45, delay: 0, options: UIView.AnimationOptions.allowUserInteraction, animations: {
                    self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                }, completion: { _ in
                    self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                })
            }
            
            if self.displayDebugging {
                let bestLocationEstimate = self.sceneLocationView.bestLocationEstimate()
                
                if bestLocationEstimate != nil {
                    if self.locationEstimateAnnotation == nil {
                        self.locationEstimateAnnotation = MKPointAnnotation()
                        self.mapView.addAnnotation(self.locationEstimateAnnotation!)
                    }
                    
                    self.locationEstimateAnnotation!.coordinate = bestLocationEstimate!.location.coordinate
                } else {
                    if self.locationEstimateAnnotation != nil {
                        self.mapView.removeAnnotation(self.locationEstimateAnnotation!)
                        self.locationEstimateAnnotation = nil
                    }
                }
            }
        }
    }
    
    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition() {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//
//        guard
//            let touch = touches.first,
//            let touchView = touch.view
//            else {
//                return
//        }
//
//        if mapView == touchView || mapView.recursiveSubviews().contains(touchView) {
//            centerMapOnUserLocation = false
//        } else {
//            let location = touch.location(in: self.view)
//            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
//                print("left side of the screen")
//                sceneLocationView.moveSceneHeadingAntiClockwise()
//            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
//                print("right side of the screen")
//                sceneLocationView.moveSceneHeadingClockwise()
//            } else {
//                let image = UIImage(named: "pin")!
//                let annotationNode = LocationAnnotationNode(location: nil, image: image)
//                annotationNode.scaleRelativeToDistance = true
//                sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
//            }
//        }
//    }
    
    @IBAction func logOutPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        }
            
        catch {
            print("There was an error while signing out.")
        }
        allAnnotations[currentUser] = sceneLocationView.locationNodes as! [LocationAnnotationNode]
        let annotationDict = ["annotations" : allAnnotations]
        print("HA", annotationDict)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "preserveAnnotations"), object: nil, userInfo: annotationDict)
        guard (navigationController?.popToRootViewController(animated: true)) != nil
            else {
                print("No view controllers to be popped off.")
                return
        }
    }
    
    @IBAction func profilePressed(_ sender: Any) {
        let profileVC = Bundle.main.loadNibNamed("ProfileViewController", owner: self, options: nil)!.first as? ProfileViewController
        profileVC?.view
        let annotationDict = ["annotations" : nodes]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAnnotations"), object: nil, userInfo: annotationDict)
        self.navigationController?.pushViewController(profileVC!, animated: true)
    }
    
    @IBAction func addEventPressed(_ sender: Any) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            let createVC = CreateAnnotationViewController.storyboardInstanceWith(rootViewController: self)
            createVC.delegate = self
            createVC.modalTransitionStyle = .crossDissolve
            createVC.modalPresentationStyle = .overCurrentContext
            self.present(createVC, animated: true)
        }
    }
    
    func constructPin(eventName: String, email: String, photo: UIImage?, elaboration: String, date: String) -> UIImage {
        let pinView = PinView(frame: CGRect(x: 0, y: 0, width: 276, height: 266))
        pinView.eventPhoto.isHidden = false
        pinView.eventTitle.text = eventName
        pinView.userEmail.text = email
        pinView.eventDescription.text = elaboration
        pinView.dateLabel.text = date
        if let thePic = photo {
            pinView.eventPhoto.image = thePic
        }
        else {
            pinView.eventPhoto.isHidden = true
        }
        return pinView.asImage()
    }
}

extension ARViewController: CreateAnnotationDelegate {
    func createAnnotation(eventName: String, email: String, photo: UIImage?, elaboration: String, date: Date) {
        print("KKKKKK", elaboration)
        let location = CGPoint(x: 279.3333282470703, y: 396.6666564941406)
        if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
            print("left side of the screen")
            sceneLocationView.moveSceneHeadingAntiClockwise()
        } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
            print("right side of the screen")
            sceneLocationView.moveSceneHeadingClockwise()
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            let dateString = dateFormatter.string(from: date)
            let image = constructPin(eventName: eventName, email: email, photo: photo, elaboration: elaboration, date: dateString)
            let annotationNode = LocationAnnotationNode(location: nil, image: image, date: dateString)
            annotationNode.scaleRelativeToDistance = true
            sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
            nodes.append(annotationNode)
        }
    }
}

// MARK: - MKMapViewDelegate
@available(iOS 11.0, *)
extension ARViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        guard let pointAnnotation = annotation as? MKPointAnnotation else {
            return nil
        }
        
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        marker.displayPriority = .required
        
        if pointAnnotation == self.userAnnotation {
            marker.glyphImage = UIImage(named: "user")
        } else {
            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named: "compass")
        }
        
        return marker
    }
}

// MARK: - SceneLocationViewDelegate
@available(iOS 11.0, *)
extension ARViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        
    }
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
        self.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: execute)
    }
}

extension UIView {
    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews
        
        for subview in subviews {
            recursiveSubviews.append(contentsOf: subview.recursiveSubviews())
        }
        
        return recursiveSubviews
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}