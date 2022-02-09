//
//  LoginViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import SwiftRant
import SwiftKeychainWrapper

class LoginViewController: UIViewController, UITextFieldDelegate {
    var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    
    var viewControllerThatPresented: UIViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //isModalInPresentation = true
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        KeyboardAvoiding.avoidingView = stackView
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        let nextResponder = textField.superview?.viewWithTag(nextTag) as? UIResponder
        
        if nextResponder != nil {
            nextResponder?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    /*func textFieldDidEndEditing(_ textField: UITextField) {
        if usernameTextField.text != nil && passwordTextField.text != nil {
            logInButton.isEnabled = true
        } else {
            logInButton.isEnabled = false
        }
    }*/
    
    @IBAction func didEditUsernameOrPassword(_ sender: Any) {
        if usernameTextField.text != "" && passwordTextField.text != "" {
            logInButton.isEnabled = true
        } else {
            logInButton.isEnabled = false
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func logIn(_ sender: Any) {
        logInButton.isUserInteractionEnabled = false
        usernameTextField.isEnabled = false
        passwordTextField.isEnabled = false
        logInButton.setTitle("", for: .normal)
        
        if activityIndicator == nil {
            activityIndicator = UIActivityIndicatorView()
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .lightGray
        }
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        logInButton.addSubview(activityIndicator)
        logInButton.centerXAnchor.constraint(equalTo: self.activityIndicator.centerXAnchor).isActive = true
        logInButton.centerYAnchor.constraint(equalTo: self.activityIndicator.centerYAnchor).isActive = true
        
        activityIndicator.startAnimating()
        
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        
        SwiftRant.shared.logIn(username: username, password: password) { error, _ in
            if error == nil, let tokenFromKeychain = SwiftRant.shared.tokenFromKeychain {
                SwiftRant.shared.getProfileFromID(tokenFromKeychain.authToken.userID, token: nil, userContentType: .rants, skip: 0) { profileRetrieveError, result in
                    if error == nil, let result = result {
                        UserDefaults.standard.set(result.avatar.backgroundColor, forKey: "DRUserColor")
                        
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.logInButton.setTitle("Log In", for: .normal)
                            self.logInButton.isUserInteractionEnabled = true
                            self.usernameTextField.isEnabled = true
                            self.passwordTextField.isEnabled = true
                            
                            (self.viewControllerThatPresented as! HomeFeedTableViewController).viewDidLoad()
                            (self.viewControllerThatPresented as! HomeFeedTableViewController).tableView.reloadData()
                            
                            
                            
                            self.navigationController!.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        let alertController = UIAlertController(title: "Error", message: profileRetrieveError ?? "An unknown error occurred while retrieving the user's profile.", preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: "Log Out and Try Again", style: .cancel, handler: { _ in
                            let keychainWrapper = KeychainWrapper(serviceName: "SwiftRant", accessGroup: "SwiftRantAccessGroup")
                            
                            let query: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                                                       kSecMatchLimit as String: kSecMatchLimitOne,
                                                       kSecReturnAttributes as String: true,
                                                       kSecReturnData as String: true,
                                                       kSecAttrLabel as String: "SwiftRant-Attached Account" as CFString
                            ]
                            
                            keychainWrapper.removeAllKeys()
                            UserDefaults.resetStandardUserDefaults()
                            SecItemDelete(query as CFDictionary)
                        }))
                        
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.logInButton.setTitle("Log In", for: .normal)
                            self.logInButton.isUserInteractionEnabled = true
                            self.usernameTextField.isEnabled = true
                            self.passwordTextField.isEnabled = true
                            
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred during logging in. Please try again.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.logInButton.setTitle("Log In", for: .normal)
                    self.logInButton.isUserInteractionEnabled = true
                    self.usernameTextField.isEnabled = true
                    self.passwordTextField.isEnabled = true
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        /*DispatchQueue.global(qos: .userInitiated).async {
            APIRequest().logIn(username: username, password: password)
            
            /*if UserDefaults.standard.integer(forKey: "DRUserID") != 0 {
                let userInfo = try! APIRequest().getProfileFromID(UserDefaults.standard.integer(forKey: "DRUserID"), userContentType: .rants, skip: 0)!
                let userColor = UIColor(hex: userInfo.profile.avatar.b)!
                //let userProfileImage = userInfo.profile.avatar.i
                
                UserDefaults.standard.set(userColor, forKey: "DRUserColor")
                //UserDefaults.standard.setValue(userProfileImage, forKey: "DRUserImage")
            }*/
            
            if UserDefaults.standard.integer(forKey: "DRUserID") != 0 {
                APIRequest().getProfileFromID(UserDefaults.standard.integer(forKey: "DRUserID"), userContentType: .rants, skip: 0, completionHandler: { result in
                    UserDefaults.standard.set(UIColor(hex: result!.profile.avatar.b)!, forKey: "DRUserColor")
                })
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.logInButton.setTitle("Log In", for: .normal)
                self.logInButton.isUserInteractionEnabled = true
                self.usernameTextField.isEnabled = true
                self.passwordTextField.isEnabled = true
                
                /*self.navigationController!.dismiss(animated: true, completion: {
                    (self.navigationController!.presentingViewController as! HomeFeedTableViewController).viewDidLoad()
                    (self.navigationController!.presentingViewController as! HomeFeedTableViewController).tableView.reloadData()
                })*/
                
                if UserDefaults.standard.integer(forKey: "DRUserID") == 0 || UserDefaults.standard.integer(forKey: "DRTokenID") == 0 || UserDefaults.standard.string(forKey: "DRTokenKey") == nil {
                    let errorAlert = UIAlertController(title: "Error", message: "One or more of the credentials you entered are incorrect. Please try again.", preferredStyle: .alert)
                    
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    
                    self.present(errorAlert, animated: true, completion: nil)
                } else {
                    
                    //let viewControllerThatInitiatedSelf = (self.navigationController!.presentingViewController as! UINavigationController).viewControllers.first!
                    //let viewControllerThatInitiatedSelf = self.presentingViewController!.navigationController!.viewControllers.first!
                    
                    //(viewControllerThatInitiatedSelf as! HomeFeedTableViewController).viewDidLoad()
                    //(viewControllerThatInitiatedSelf as! HomeFeedTableViewController).tableView.reloadData()
                    
                    (self.viewControllerThatPresented as! HomeFeedTableViewController).viewDidLoad()
                    (self.viewControllerThatPresented as! HomeFeedTableViewController).tableView.reloadData()
					
					
                    
                    self.navigationController!.dismiss(animated: true, completion: nil)
                }
            }
        }*/
    }
}
