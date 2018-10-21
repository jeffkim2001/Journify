//
//  ViewController.swift
//  Journify
//
//  Created by Jeff Kim on 10/20/18.
//  Copyright © 2018 Jeff Kim. All rights reserved.
//

import UIKit
import ARKit
import FirebaseAuth
import SVProgressHUD
import SCLAlertView

class LogInViewController: UIViewController {


    
    @IBOutlet weak var registerFromLogInButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var blackView: UIView!
    @IBOutlet weak var appIcon: UIImageView!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var logInButton: UIButton!
    let textAttributes = [NSAttributedString.Key.font : UIFont(name: "Helvetica-Light", size: 20), NSAttributedString.Key.foregroundColor : UIColor.white]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameField.drawTextField()
        userNameField.placeholder = "Email"
        passwordField.placeholder = "Password"
        passwordField.drawTextField()
        registerButton.setAttributedTitle(NSAttributedString(string: "Register", attributes: textAttributes), for: .normal)
        logInButton.setAttributedTitle(NSAttributedString(string: "Log In", attributes: textAttributes), for: .normal)
        registerFromLogInButton.setAttributedTitle(NSAttributedString(string: "Register", attributes: textAttributes), for: .normal)
        cancelButton.setAttributedTitle(NSAttributedString(string: "Cancel", attributes: textAttributes), for: .normal)
        registerFromLogInButton.alpha = 1.0
        logInButton.alpha = 1.0
        cancelButton.alpha = 0
        registerButton.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    @IBAction func registerPressed(_ sender: Any) {
        UIView.animate(withDuration: 1, animations: {
            self.registerFromLogInButton.alpha = 0.0
            self.logInButton.alpha = 0.0
            self.appIcon.alpha = 0.0
            self.passwordField.alpha = 0.0
            self.userNameField.alpha = 0.0
        }, completion: nil)
        UIView.animate(withDuration: 1, animations: {
            self.cancelButton.alpha = 1.0
            self.registerButton.alpha = 1.0
            self.appIcon.alpha = 1.0
            self.passwordField.alpha = 1.0
            self.userNameField.alpha = 1.0
        }, completion: nil)
        
    }
    
    func goBackToLogIn() {
        UIView.animate(withDuration: 1, animations: {
            self.cancelButton.alpha = 0.0
            self.registerButton.alpha = 0.0
            self.appIcon.alpha = 0.0
            self.passwordField.alpha = 0.0
            self.userNameField.alpha = 0.0
        }, completion: nil)
        UIView.animate(withDuration: 1, animations: {
            self.cancelButton.alpha = 0.0
            self.registerButton.alpha = 0.0
            self.logInButton.alpha = 1.0
            self.registerFromLogInButton.alpha = 1.0
            self.appIcon.alpha = 1.0
            self.passwordField.alpha = 1.0
            self.userNameField.alpha = 1.0
        }, completion: nil)
        self.passwordField.text = ""
        self.userNameField.text = ""
    }
    
    @IBAction func finalRegisterPressed(_ sender: Any) {
        SVProgressHUD.show()
        Auth.auth().createUser(withEmail: userNameField.text!, password: passwordField.text!, completion: { (user, error) in
            if error != nil {
                print(error!)
            }
                
            else{
                print("Registration Successful!")
                SVProgressHUD.dismiss()
                let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(
                    kTitleFont: UIFont(name: "HelveticaNeue-Light", size: 20)!,
                    kTextFont: UIFont(name: "HelveticaNeue-Light", size: 14)!,
                    kButtonFont: UIFont(name: "HelveticaNeue-Light", size: 14)!,
                    showCloseButton: false
                ))
                alert.addButton("OK", action: {
                    alert.dismiss(animated: true, completion: nil)
                })
                alert.showSuccess("Registration Successful", subTitle: "Your registration was successful!")
                self.goBackToLogIn()
            }
        }
            
        )
    }
    
    @IBAction func logInPressed(_ sender: Any) {
        SVProgressHUD.show()
        
        Auth.auth().signIn(withEmail: userNameField.text!, password: passwordField.text!, completion: { (user, error) in
            
            if error != nil {
                print(error!)
            }
                
            else {
                print("Log in was successful.")
                SVProgressHUD.dismiss()
                let userID = Auth.auth().currentUser!.uid
                let arVC = Bundle.main.loadNibNamed("ARViewController", owner: self, options: nil)!.first as? ARViewController
                self.navigationController?.pushViewController(arVC!, animated: true)
            }
        })
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        goBackToLogIn()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}



extension UITextField {
    
    func drawTextField() {
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.cornerRadius = 0
        self.layer.borderWidth = 1.0
        self.backgroundColor = UIColor.white
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        self.addConstraint(heightConstraint)
    }
    
}
