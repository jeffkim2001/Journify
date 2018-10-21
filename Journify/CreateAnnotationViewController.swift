//
//  CreateAnnotationViewController.swift
//  Journify
//
//  Created by Jeff Kim on 10/20/18.
//  Copyright © 2018 Jeff Kim. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import SVProgressHUD
import CoreLocation
import Firebase

protocol CreateAnnotationDelegate {
    func createAnnotation(eventName: String, email: String)
}

class CreateAnnotationViewController: UIViewController {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var eventNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var descriptionField: UITextView!
    let imagePicker = UIImagePickerController()
    weak var rootViewController: UIViewController?
    var imageArray: [UIImage] = []
    var delegate: CreateAnnotationDelegate!
    var location: CLLocation!
    var eventName: String = ""

    
    static func storyboardInstanceWith(rootViewController: UIViewController) -> CreateAnnotationViewController {
        let vc = CreateAnnotationViewController(nibName: "CreateAnnotationViewController", bundle: nil)
        vc.rootViewController = rootViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nibName = UINib(nibName: "PhotoCollectionViewCell", bundle:nil)
        photoCollectionView.register(nibName, forCellWithReuseIdentifier: "photoCollectionViewCell")
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setShadowContentView()
    }
    
    func setShadowContentView() {
        contentView.layer.masksToBounds = false
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.3
        contentView.layer.shadowOffset = CGSize.zero
        contentView.layer.shadowRadius = 5
        contentView.layer.shadowPath = UIBezierPath(rect: contentView.bounds).cgPath
        contentView.layer.shouldRasterize = false
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func postPressed(_ sender: Any) {
        self.delegate.createAnnotation(eventName: eventNameField.text!, email: (Auth.auth().currentUser?.email)!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPhotoPressed(_ sender: Any) {
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.allowsEditing = false
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

extension CreateAnnotationViewController: UICollectionViewDelegate {
    
}

extension CreateAnnotationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 87, height: 118);
    }
}

extension CreateAnnotationViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.selectedImage.image = imageArray[indexPath.item]
        return cell
    }

}

extension CreateAnnotationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            imagePicker.dismiss(animated: true, completion: nil)
            imageArray.append(image)
            photoCollectionView.reloadData()
            let imageData = image.jpegData(compressionQuality: 0.01) as NSData?
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("tempImage.jpeg")
        }
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    
}


