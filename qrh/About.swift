//
//  About.swift
//  qrh
//
//  Created by user185107 on 10/24/20.
//

import UIKit

class About: UIViewController {

    
    @IBOutlet weak var ccImage: UIImageView!
    
    @IBOutlet weak var version: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(closeModal))
        
        let ccImageClicked = UITapGestureRecognizer(target: self, action: #selector(openCcLink))
        ccImage.addGestureRecognizer(ccImageClicked)
        

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
           self.version.text = "Version \(version)"
       }
    }
    
    @objc func closeModal() {
        self.dismiss(animated: true, completion:nil)
    }
    
    @objc func openCcLink() {
        if let ccURL = URL(string: "https://creativecommons.org/licenses/by-nc-sa/4.0/") {
            UIApplication.shared.open(ccURL, options: [:], completionHandler: nil)
        }
        
    }

   
}
