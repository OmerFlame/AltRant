//
//  LoginViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit

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
        
        DispatchQueue.global(qos: .userInitiated).async {
            APIRequest().logIn(username: self.usernameTextField.text!, password: self.passwordTextField.text!)
            
            if UserDefaults.standard.integer(forKey: "DRUserID") != 0 {
                let userInfo = try! APIRequest().getProfileFromID(UserDefaults.standard.integer(forKey: "DRUserID"), userContentType: .rants, skip: 0)!
                let userColor = UIColor(hex: userInfo.profile.avatar.b)!
                //let userProfileImage = userInfo.profile.avatar.i
                
                UserDefaults.standard.set(userColor, forKey: "DRUserColor")
                //UserDefaults.standard.setValue(userProfileImage, forKey: "DRUserImage")
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
        }
    }
}
