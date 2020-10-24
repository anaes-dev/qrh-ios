//
//  CardCell10.swift
//  qrh
//
//  Created by user185107 on 10/24/20.
//

import UIKit

class CardCell10: UITableViewCell {

    @IBOutlet var imageFile: UIImageView!
    @IBOutlet var head: UILabel!
    
    @IBOutlet weak var imageContainer: UIView!
    
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
