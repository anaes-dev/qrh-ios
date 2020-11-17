//
//  BcButton.swift
//  qrh
//
//  Created by user185107 on 11/17/20.
//

import UIKit

class BreadcrumbButton: UIButton {

    func formatBc() {
        self.setTitleColor(UIColor.systemTeal, for: .normal)
        self.setTitleColor(UIColor.systemTeal.withAlphaComponent(0.7), for: .highlighted)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        self.imageView?.contentMode = .scaleAspectFit
        self.contentEdgeInsets.right = 8
        self.titleEdgeInsets.left = 4
        self.titleEdgeInsets.right = -4
        self.adjustsImageWhenHighlighted = false
        self.heightAnchor.constraint(equalToConstant: 32).isActive = true
        self.contentVerticalAlignment = .center
    }
    
    func homeBc() {
        self.setTitle("Home", for: .normal)
        self.setImage(UIImage(systemName: "house"), for: .normal)
        self.setImage(UIImage(systemName: "house")?.withRenderingMode(.alwaysOriginal).withTintColor(UIColor.systemTeal.withAlphaComponent(0.7)), for: .highlighted)
    }
    
    func chevronBc(title: String, index: Int) {
        self.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        self.setTitle(title, for: .normal)
        self.tag = index + 1
    }

}
