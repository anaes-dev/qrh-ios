//
//  CardCell1.swift
//  qrh
//
//  Created by user185107 on 10/15/20.
//

import UIKit

class CardCell1: UITableViewCell {

    @IBOutlet weak var main: UILabel!
    
    @IBOutlet weak var code: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
