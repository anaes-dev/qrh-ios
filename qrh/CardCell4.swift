//
//  CardCell4.swift
//  qrh
//
//  Created by user185107 on 10/15/20.
//

import UIKit

class CardCell4: UITableViewCell {

    @IBOutlet weak var body: UITextView!
    @IBOutlet weak var step: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        body.isUserInteractionEnabled = true
        body.isEditable = false
        body.isSelectable = true
        body.isScrollEnabled = false
    }

}
