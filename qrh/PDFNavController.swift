//
//  PDFNavController.swift
//  qrh
//
//  Created by user185107 on 10/17/20.
//

import UIKit

class PDFNavController: UINavigationController {
      var passedURL = String()
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PDFController {
            destination.passedURL = passedURL
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.performSegue(withIdentifier: "LoadPDF2", sender: self)
    }
}
