//
//  GuidelineListCell.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

class GuidelineListCell: UICollectionViewCell {
    @IBOutlet weak var MAIN: UILabel!
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return contentView.systemLayoutSizeFitting(CGSize(width: self.bounds.size.width, height: 1))
    }
}
