//
//  About.swift
//  qrh
//
//  Created by user185107 on 10/24/20.
//

import UIKit

class About: UIViewController {

    
    @IBOutlet weak var ccImage: UIImageView!
    
//    @IBOutlet weak var disableDarkMode: UISwitch!
    
    @IBOutlet weak var privacy: UIButton!
    
    @IBOutlet weak var version: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(closeModal))
        
        let ccImageClicked = UITapGestureRecognizer(target: self, action: #selector(openCcLink))
        ccImage.addGestureRecognizer(ccImageClicked)
        

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
           self.version.text = "Version \(version)"
       }
        
        privacy.addTarget(self, action: #selector(openPrivacyLink), for: .touchUpInside)
        
        
//        disableDarkMode.addTarget(self, action: #selector(darkModeSwitch), for: UIControl.Event.valueChanged)
         
    }
    
    @objc func closeModal() {
        self.dismiss(animated: true, completion:nil)
    }
    
    @objc func openCcLink() {
        if let ccURL = URL(string: "https://creativecommons.org/licenses/by-nc-sa/4.0/") {
            UIApplication.shared.open(ccURL, options: [:], completionHandler: nil)
        }
    }
    
    @objc func openPrivacyLink() {
        if let privacyUrl = URL(string: "http://qrh.anaes.dev/privacy") {
            UIApplication.shared.open(privacyUrl, options: [:], completionHandler: nil)
        }
    }
    
//    @objc func darkModeSwitch(darkSwitch: UISwitch) {
//        if(darkSwitch.isOn) {
//            UserDefaults.standard.set(true, forKey: "disableDarkMode")
//        } else {
//            UserDefaults.standard.set(false, forKey: "disableDarkMode")
//        }
//    }

   
}
