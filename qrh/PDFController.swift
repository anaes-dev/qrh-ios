//
//  PDFController.swift
//  qrh
//
//  Created by user185107 on 10/17/20.
//

import UIKit
import WebKit

class PDFController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    var passedURL = String()
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: passedURL)
            let request = URLRequest(url : url!)
            webView.load(request)
        
        self.navigationItem.title = "Original PDF"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeTapped))

    }
    
    @objc func closeTapped(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
