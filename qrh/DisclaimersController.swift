//
//  DisclaimersController.swift
//  qrh
//
//  Created by user185107 on 10/25/20.
//

import UIKit

class DisclaimersController: UIViewController {

    @IBOutlet weak var agree: UIButton!
    @IBOutlet weak var disagree: UIButton!
    
    @IBOutlet weak var ccImage: UIImageView!
    @IBOutlet weak var version: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true

        agree.addTarget(self, action: #selector(agreeTapped), for: .touchUpInside)
        disagree.addTarget(self, action: #selector(disagreeTapped), for: .touchUpInside)
        
        
        let ccImageClicked = UITapGestureRecognizer(target: self, action: #selector(openCcLink))
        ccImage.addGestureRecognizer(ccImageClicked)
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
           self.version.text = "Version \(version)"
       }
        
    }
    
    @objc func agreeTapped(sender:UIButton) {
        UserDefaults.standard.set(true, forKey: "hasAcceptedDisclaimer")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func openCcLink() {
        if let ccURL = URL(string: "https://creativecommons.org/licenses/by-nc-sa/4.0/") {
            UIApplication.shared.open(ccURL, options: [:], completionHandler: nil)
        }
    }
    
    @objc func disagreeTapped(sender:UIButton) {
        let alert = UIAlertController(title: "Thank you for your time", message: "Please close and uninstall the app", preferredStyle: .alert)
        self.present(alert, animated: true)
    }

}
