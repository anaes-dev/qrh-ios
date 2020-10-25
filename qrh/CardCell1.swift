//
//  CardCell1.swift
//  qrh
//
//  Created by user185107 on 10/15/20.
//

import UIKit

class CardCell1: UITableViewCell {

    
    @IBOutlet weak var code: UILabel!
    
    @IBOutlet weak var body: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        body.isUserInteractionEnabled = true
        body.isEditable = false
        body.isSelectable = true
        body.isScrollEnabled = false
    }

}
