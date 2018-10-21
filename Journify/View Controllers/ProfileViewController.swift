//
//  ProfileViewController.swift
//  Journify
//
//  Created by Jeff Kim on 10/20/18.
//  Copyright © 2018 Jeff Kim. All rights reserved.
//

import UIKit
import MapKit
import ARCL
import Firebase

class ProfileViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var eventMapView: MKMapView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var statCollectionView: UICollectionView!
    var annotationArray: [LocationAnnotationNode] = []
    
    @objc func updateAnnotations(_ notification: NSNotification) {
        if let annotations = notification.userInfo?["annotations"] as? [LocationAnnotationNode] {
            annotationArray = annotations
            statCollectionView.reloadData()
            if annotationArray.count > 0 {
                for index in 0 ..< annotationArray.count {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = annotationArray[index].location.coordinate
                    eventMapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userEmail.text = Auth.auth().currentUser?.email
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAnnotations(_:)), name: Notification.Name(rawValue: "updateAnnotations"), object: nil)
//        eventMapView.delegate = self
        statCollectionView.delegate = self
        statCollectionView.dataSource = self
        statCollectionView.register(UINib(nibName: "StatCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "statCollectionViewCell")
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func calculateActiveDays(annotations: [LocationAnnotationNode]) -> Int {
        var dates = [String]()
        for index in 0..<annotations.count {
            let date = annotations[index].date
            if !dates.contains(date!) {
                dates.append(date!)
            }
        }
        return dates.count
    }


}

//extension ProfileViewController: MKMapViewDelegate {
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard annotation is MKPointAnnotation else { return nil }
//
//        let identifier = "Annotation"
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//
//        if annotationView == nil {
//            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            annotationView!.canShowCallout = true
//        } else {
//            annotationView!.annotation = annotation
//        }
//
//        return annotationView
//    }
//}

extension ProfileViewController: UICollectionViewDelegate {
    
}

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "statCollectionViewCell", for: indexPath) as! StatCollectionViewCell
        if indexPath.item == 0 {
            cell.statName.text = "Events"
            cell.stat.text = "\(annotationArray.count)"
        }
        else if indexPath.item == 1 {
            cell.statName.text = "Active Days"
            if annotationArray.count > 0 {
                cell.stat.text = "\(calculateActiveDays(annotations: annotationArray))"
            }
            else {
                cell.stat.text = "\(0)"
            }
        }
        return cell
    }
    
    
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width/3, height: collectionView.bounds.height - 5);
    }
}
