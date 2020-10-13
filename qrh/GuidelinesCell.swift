//
//  GuidelinesCell.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

class GuidelinesCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var code: UILabel!
    @IBOutlet weak var version: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
