//
//  CardCell5.swift
//  qrh
//
//  Created by user185107 on 10/17/20.
//

import UIKit

class CardCell5: UITableViewCell {

    @IBOutlet weak var main: UILabel!
    

    @IBOutlet weak var sub: UITextView!
    
    @IBOutlet weak var arrow: UIImageView!

    
    
    @IBOutlet weak var sub8: NSLayoutConstraint!
    
    @IBOutlet weak var sub0: NSLayoutConstraint!
    
    @IBOutlet weak var box: UIView!
    
    @IBOutlet weak var button: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0)
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
