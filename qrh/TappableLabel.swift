//
//  TappableLabel.swift
//  qrh
//
//  Created by user185107 on 10/19/20.
//

import UIKit

typealias ElementTuple = (range: NSRange, element: ActiveElement, type: ActiveType)

public typealias ConfigureLinkAttribute = (ActiveType, [NSAttributedString.Key : Any], Bool) -> ([NSAttributedString.Key : Any])
typealias ElementTuple = (range: NSRange, element: ActiveElement, type: ActiveType)

class TapabbleLabel: UILabel {

let layoutManager = NSLayoutManager()
let textContainer = NSTextContainer(size: CGSize.zero)
var textStorage = NSTextStorage() {
    didSet {
        textStorage.addLayoutManager(layoutManager)
    }
}

    var onCharacterTapped: ((_ label: UILabel, _ characterIndex: Int) -> Void)?
    fileprivate var heightCorrection: CGFloat = 0

let tapGesture = UITapGestureRecognizer()

override var attributedText: NSAttributedString? {
    didSet {
        if let attributedText = attributedText {
            textStorage = NSTextStorage(attributedString: attributedText)
        } else {
            textStorage = NSTextStorage()
        }
    }
}

override var lineBreakMode: NSLineBreakMode {
    didSet {
        textContainer.lineBreakMode = lineBreakMode
    }
}

override var numberOfLines: Int {
    didSet {
        textContainer.maximumNumberOfLines = numberOfLines
    }
}

/**
 Creates a new view with the passed coder.

 :param: aDecoder The a decoder

 :returns: the created new view.
 */
required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setUp()
}

/**
 Creates a new view with the passed frame.

 :param: frame The frame

 :returns: the created new view.
 */
override init(frame: CGRect) {
    super.init(frame: frame)
    setUp()
}
    lazy var activeElements = [ActiveType: [ElementTuple]]()

/**
 Sets up the view.
 */
func setUp() {
    isUserInteractionEnabled = true
    layoutManager.addTextContainer(textContainer)
    textContainer.lineFragmentPadding = 0
    textContainer.lineBreakMode = lineBreakMode
    textContainer.maximumNumberOfLines = numberOfLines
    tapGesture.addTarget(self, action: #selector(labelTapped))
    addGestureRecognizer(tapGesture)
}
    
    fileprivate func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    open override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
    
    fileprivate func element(at location: CGPoint) -> ElementTuple? {
        guard textStorage.length > 0 else {
            return nil
        }
        
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        
        for element in activeElements.map({ $0.1 }).joined() {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
            }
        }
        
        return nil
    }
    

override func layoutSubviews() {
    super.layoutSubviews()
    textContainer.size = bounds.size
}

    @objc func labelTapped(gesture: UITapGestureRecognizer) {
    guard gesture.state == .ended else {
        return
    }

    let locationOfTouch = gesture.location(in: gesture.view)
    let textBoundingBox = layoutManager.usedRect(for: textContainer)
    let labelSize = gesture.view?.bounds.size
    let textContainerOffset = CGPoint(x: ((labelSize?.width)! - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: ((labelSize?.height)! - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
    let locationOfTouchInTextContainer = CGPoint(x: locationOfTouch.x - textContainerOffset.x,
                                                 y: locationOfTouch.y - textContainerOffset.y)
    let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                        in: textContainer,
                                                                fractionOfDistanceBetweenInsertionPoints: nil)

    onCharacterTapped?(self, indexOfCharacter)
}
}
