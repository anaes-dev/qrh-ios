//
//  CardCell5.swift
//  qrh
//
//  Created by user185107 on 10/17/20.
//

import UIKit

class CardCell5: UITableViewCell {

    @IBOutlet weak var head: UILabel!
    
    @IBOutlet weak var body: UITextView!
    
    @IBOutlet weak var arrow: UIImageView!
    
    @IBOutlet weak var sub8: NSLayoutConstraint!
    
    @IBOutlet weak var sub0: NSLayoutConstraint!
    
    @IBOutlet weak var subheight: NSLayoutConstraint!
    
    @IBOutlet weak var box: UIView!
    
    @IBOutlet weak var button: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        body.isUserInteractionEnabled = true
        body.isEditable = false
        body.isSelectable = true
        body.isScrollEnabled = false
    }
    
}
