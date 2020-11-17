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
    
    func boxCol(type: Int){
        switch type {
        case 5:
            box.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
            button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0)
            head.textColor = UIColor.systemOrange
            arrow.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
            arrow.tintColor = UIColor.systemOrange
        case 6:
            box.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0)
            head.textColor = UIColor.systemBlue
            arrow.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            arrow.tintColor = UIColor.systemBlue
        case 7:
            box.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
            button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0)
            head.textColor = UIColor.systemGreen
            arrow.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            arrow.tintColor = UIColor.systemGreen
        case 9:
            box.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.15)
            button.backgroundColor = UIColor.systemPurple.withAlphaComponent(0)
            head.textColor = UIColor.systemPurple
            arrow.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
            arrow.tintColor = UIColor.systemPurple
        default:
            box.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
            button.backgroundColor = UIColor.systemGray.withAlphaComponent(0)
            head.textColor = UIColor.label
            arrow.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
            arrow.tintColor = UIColor.label
        }
    }

    
}
