//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

class DetailController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    struct Card: Codable {
        var type: Int
        var main: String
        var sub: String
        var step: String
    }
    
    struct Cards: Codable {
        var DetailContent: [Card]
    }
        
    var cardContent = [Card]()
    
    var passedCode = String()
    var passedTitle = String()
    var passedURL = String()
    var scrubLink = String()
    var fetchedURL: String = ""
    var fetchedTitle: String = "Default"
    
    
    struct Guideline: Codable {
        var code: String
        var title: String
        var version: Int
        var url: String
    }
    
    struct GuidelineList: Codable {
        var guidelines: [Guideline]
    }
        
    var unfilteredGuidelines = [Guideline]()
    var filteredGuidelines = [Guideline]()
    
    var subParsed = Array<NSMutableAttributedString>()
    var mainParsed = Array<NSMutableAttributedString>()
    
    var expandedIndexSet : IndexSet = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "CardCell1", bundle: nil), forCellReuseIdentifier: "CardCell1")
        tableView.register(UINib(nibName: "CardCell2", bundle: nil), forCellReuseIdentifier: "CardCell2")
        tableView.register(UINib(nibName: "CardCell3", bundle: nil), forCellReuseIdentifier: "CardCell3")
        tableView.register(UINib(nibName: "CardCell4", bundle: nil), forCellReuseIdentifier: "CardCell4")
        tableView.register(UINib(nibName: "CardCell5", bundle: nil), forCellReuseIdentifier: "CardCell5")
        tableView.register(UINib(nibName: "CardCell9", bundle: nil), forCellReuseIdentifier: "CardCell9")
        tableView.register(UINib(nibName: "CardCell11", bundle: nil), forCellReuseIdentifier: "CardCell11")
        tableView.register(UINib(nibName: "CardCell12", bundle: nil), forCellReuseIdentifier: "CardCell12")

        
        let jsonURL = Bundle.main.url(forResource: passedCode, withExtension: "json")!
        if let jsonDATA = try? Data(contentsOf: jsonURL) {
           parseCards(json: jsonDATA)
        }
        
        
        let pdfButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(urlTapped))
        self.navigationItem.rightBarButtonItem = pdfButton

        self.navigationItem.title = passedTitle
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cardContent.count
    }
    

    @objc func urlTapped(sender: AnyObject) {
        self.performSegue(withIdentifier: "LoadPDF", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PDFNavController {
            destination.passedURL = passedURL
        }
        
        if let destination = segue.destination as? DetailController {
            let jsonURL = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
            if let jsonDATA = try? Data(contentsOf: jsonURL) {
                let decoder = JSONDecoder()
                if let jsonGuidelines = try? decoder.decode(GuidelineList.self, from: jsonDATA) {
                    unfilteredGuidelines = jsonGuidelines.guidelines
                    filteredGuidelines = unfilteredGuidelines.filter { (guideline: Guideline) -> Bool in
                        return guideline.code.lowercased().contains(scrubLink)
                    }
                    fetchedURL = filteredGuidelines[0].url
                    fetchedTitle = filteredGuidelines[0].title
            }
            destination.passedCode = scrubLink
            destination.passedURL = fetchedURL
            destination.passedTitle = fetchedTitle
        }
        }
        
    }
    
    @objc func tapBox(sender: UILongPressGestureRecognizer) {
        if let buttonView = sender.view {
            let existingColor = buttonView.backgroundColor
            if sender.state == .began {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0.1)
            } else if sender.state == .ended {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0)
                if let cell = buttonView.superview?.superview?.superview?.superview as? UITableViewCell {
                    if let indexPath = tableView.indexPath(for: cell) {
                        if(expandedIndexSet.contains(indexPath.row)){
                            expandedIndexSet.remove(indexPath.row)
                            } else {
                                expandedIndexSet.insert(indexPath.row)
                            }

                        self.tableView.reloadRows(at: [indexPath], with: .none)

    
                        return
                        }
                }
            } else if sender.state == .cancelled {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0)
                return
            
        }
        } else {
            return
        }
        
    }
    

    
    
    
    
//    @objc func tapLink(gesture: UITapGestureRecognizer) {
//        print("hello")
//        if let tappedLabel = gesture.view as? TapabbleLabel {
//            tappedLabel.onCharacterTapped = { label, characterIndex in
//            if let attribute = tappedLabel.attributedText?.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) as? String,
//                let url = NSURL(string: attribute) {
//                print(url)
//            }
//        }
//        }
//
//    }
    
    
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch cardContent[indexPath.row].type {
            
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.main.attributedText = mainParsed[indexPath.row]
                return cell
            
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                cell.main.text = cardContent[indexPath.row].main
                cell.sub.attributedText = subParsed[indexPath.row]
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                cell.main.attributedText = mainParsed[indexPath.row]
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 5,6,7,8:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell5") as! CardCell5
                cell.main.text = cardContent[indexPath.row].main
                cell.sub.attributedText = subParsed[indexPath.row]
                
                let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(tapBox))
                tapGesture.minimumPressDuration = 0
                cell.button.addGestureRecognizer(tapGesture)
                                
//                let linkGesture = UITapGestureRecognizer(target: self, action: #selector(tapLink))
//                cell.sub.isUserInteractionEnabled = true
//                cell.sub.addGestureRecognizer(linkGesture)
                
                if expandedIndexSet.contains(indexPath.row) {
                    cell.arrow.image = UIImage(systemName: "arrow.up")
                } else {
                    cell.arrow.image = UIImage(systemName: "arrow.down")
                }
                                
//                if let subLable = cell.sub {
//                    subLable.onCharacterTapped = { label, characterIndex in
//                    if let attribute = subLable.attributedText?.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) as? String {
//
//                        self.scrubLink = attribute
//                        self.performSegue(withIdentifier: "LoadDetailLink", sender: self)
//                    }
//
//                }
//
//                }

                return cell
                
            case 9:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell9") as! CardCell9
                
                
//                let customLink = ActiveType.custom(pattern: "[(]?[→][\\s]?[1-4][-][0-9]{1,2}[)]?")
//                cell.sub.numberOfLines = 0
//                cell.sub.enabledTypes = [.url, customLink]
//                cell.sub.customColor[customLink] = UIColor.systemBlue
//                cell.sub.setHTMLFromString(htmlText: subInput)
                
                cell.main.text = cardContent[indexPath.row].main
                cell.sub.attributedText = subParsed[indexPath.row]
                
//                cell.sub.handleCustomTap(for: customLink) { element in
//                    self.scrubLink = element.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "→", with: "").replacingOccurrences(of: " ", with: "")
//                    self.performSegue(withIdentifier: "LoadDetailLink", sender: self)
//                }
                
                return cell
                
            case 11:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell11") as! CardCell11
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            case 12:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell12") as! CardCell12
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.main.text = cardContent[indexPath.row].main
                return cell
            
        }
         

    }
      
    
    func parseCards(json: Data) {
        let decoder = JSONDecoder()
        if let jsonCards = try? decoder.decode(Cards.self, from: json) {
            cardContent = jsonCards.DetailContent
            
            for card in cardContent {
                subParsed.append(parseHtmlAttributes(htmlText: card.sub))
                mainParsed.append(parseHtmlAttributes(htmlText: card.main))
            }
            
            tableView.reloadData()
        }
    }
    


    func parseHtmlAttributes(htmlText: String) -> NSMutableAttributedString {
    
    let htmlInput = """
                    <style type=\"text/css\">
                    body {
                        font-family: -apple-system, 'HelveticaNeue';
                    }
                    ul {
                        padding: 8px 0 0 0;
                    }
                    li {
                        margin: 0 0 8 0;
                    }
                    </style>
                    \(htmlText)
                    """
    
//
//        let htmlInput = String(format:"<html><style type=\"text/css\">html { font-family: '-apple-system', 'HelveticaNeue'; font-size: \(self.font!.pointSize); } ul { padding: 8px 0 0 0; } li { margin: 0 0 8 0;  }</style>%@", htmlText)
           
    let attrStr = try! NSMutableAttributedString(
        data: htmlInput.data(using: .unicode, allowLossyConversion: true)!,
        options: [.documentType: NSMutableAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
        documentAttributes: nil)

    if let lastCharacter = attrStr.string.last, lastCharacter == "\n" {
        attrStr.deleteCharacters(in: NSRange(location: attrStr.length-1, length: 1))
    }
    
    attrStr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length:attrStr.length))

    let unwrapped = attrStr.string
    let pattern = "[(]?[→][\\s]?[1-4][-][0-9]{1,2}[)]?"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let range = NSMakeRange(0, attrStr.length)
    let matches = regex.matches(in: unwrapped, options: [], range: range)

    for match in matches {
        print(match.range)
        let stringRange = match.range
        let stringLink = (unwrapped as NSString).substring(with: stringRange)
        let scrubLink = stringLink.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "→", with: "").replacingOccurrences(of: " ", with: "")
        attrStr.addAttribute(NSAttributedString.Key.link, value: scrubLink, range: match.range)
    }
        
//        let paragraphStyle = NSMutableParagraphStyle()
//        var minimumLineHeight: CGFloat = 0
//        var lineSpacing: CGFloat = 0
//        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
//        paragraphStyle.alignment = .natural
//        paragraphStyle.lineSpacing = lineSpacing
//        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: self.font.pointSize * 1.14
//        attrStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)

    return attrStr
}
}

extension UITextView {
    func setHTMLFromString(htmlText: String) {
        
        let htmlInput = """
                        <style type=\"text/css\">
                        body {
                            font-family: -apple-system, 'HelveticaNeue';
                            font-size: \(self.font!.pointSize);
                        }
                        ul {
                            padding: 8px 0 0 0;
                        }
                        li {
                            margin: 0 0 8 0;
                        }
                        </style>
                        \(htmlText)
                        """
        
//
//        let htmlInput = String(format:"<html><style type=\"text/css\">html { font-family: '-apple-system', 'HelveticaNeue'; font-size: \(self.font!.pointSize); } ul { padding: 8px 0 0 0; } li { margin: 0 0 8 0;  }</style>%@", htmlText)
               
        let attrStr = try! NSMutableAttributedString(
            data: htmlInput.data(using: .unicode, allowLossyConversion: true)!,
            options: [.documentType: NSMutableAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
            documentAttributes: nil)

        if let lastCharacter = attrStr.string.last, lastCharacter == "\n" {
            attrStr.deleteCharacters(in: NSRange(location: attrStr.length-1, length: 1))
        }
        
        attrStr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length:attrStr.length))

        let unwrapped = attrStr.string
        let pattern = "[(]?[→][\\s]?[1-4][-][0-9]{1,2}[)]?"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSMakeRange(0, attrStr.length)
        let matches = regex.matches(in: unwrapped, options: [], range: range)

        for match in matches {
            print(match.range)
            let stringRange = match.range
            let stringLink = (unwrapped as NSString).substring(with: stringRange)
            let scrubLink = stringLink.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "→", with: "").replacingOccurrences(of: " ", with: "")
            attrStr.addAttribute(NSAttributedString.Key.link, value: scrubLink, range: match.range)
        }
            
//        let paragraphStyle = NSMutableParagraphStyle()
//        var minimumLineHeight: CGFloat = 0
//        var lineSpacing: CGFloat = 0
//        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
//        paragraphStyle.alignment = .natural
//        paragraphStyle.lineSpacing = lineSpacing
//        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: self.font.pointSize * 1.14
//        attrStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)

        
                
        self.attributedText = attrStr
                
    }
    
}

extension UILabel {
    func setHTMLFromString(htmlText: String) {
        
        let htmlInput = """
                        <style type=\"text/css\">
                        body {
                            font-family: -apple-system, 'HelveticaNeue';
                            font-size: \(self.font!.pointSize);
                        }
                        ul {
                            padding: 8px 0 0 0;
                        }
                        li {
                            margin: 0 0 8 0;
                        }
                        </style>
                        \(htmlText)
                        """
        
//
//        let htmlInput = String(format:"<html><style type=\"text/css\">html { font-family: '-apple-system', 'HelveticaNeue'; font-size: \(self.font!.pointSize); } ul { padding: 8px 0 0 0; } li { margin: 0 0 8 0;  }</style>%@", htmlText)
               
        let attrStr = try! NSMutableAttributedString(
            data: htmlInput.data(using: .unicode, allowLossyConversion: true)!,
            options: [.documentType: NSMutableAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
            documentAttributes: nil)

        if let lastCharacter = attrStr.string.last, lastCharacter == "\n" {
            attrStr.deleteCharacters(in: NSRange(location: attrStr.length-1, length: 1))
        }
        
        attrStr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length:attrStr.length))

        let unwrapped = attrStr.string
        let pattern = "[(]?[→][\\s]?[1-4][-][0-9]{1,2}[)]?"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSMakeRange(0, attrStr.length)
        let matches = regex.matches(in: unwrapped, options: [], range: range)

        for match in matches {
            print(match.range)
            let stringRange = match.range
            let stringLink = (unwrapped as NSString).substring(with: stringRange)
            let scrubLink = stringLink.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "→", with: "").replacingOccurrences(of: " ", with: "")
            attrStr.addAttribute(NSAttributedString.Key.link, value: scrubLink, range: match.range)
        }
            
//        let paragraphStyle = NSMutableParagraphStyle()
//        var minimumLineHeight: CGFloat = 0
//        var lineSpacing: CGFloat = 0
//        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
//        paragraphStyle.alignment = .natural
//        paragraphStyle.lineSpacing = lineSpacing
//        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: self.font.pointSize * 1.14
//        attrStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)

        
                
        self.attributedText = attrStr
                
    }
    
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
