//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

class DetailController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
        
    @IBOutlet weak var tableViewMain: UITableView!
    @IBOutlet weak var tableViewRight: UITableView!
    
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
    var cellOneDIsplayCode: Bool = true
    
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
    
    var tableViewMainHidden : IndexSet = []
    var tableViewRightHidden : IndexSet = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewMain.register(UINib(nibName: "CardCell1", bundle: nil), forCellReuseIdentifier: "CardCell1")
        tableViewMain.register(UINib(nibName: "CardCell2", bundle: nil), forCellReuseIdentifier: "CardCell2")
        tableViewMain.register(UINib(nibName: "CardCell3", bundle: nil), forCellReuseIdentifier: "CardCell3")
        tableViewMain.register(UINib(nibName: "CardCell4", bundle: nil), forCellReuseIdentifier: "CardCell4")
        tableViewMain.register(UINib(nibName: "CardCell5", bundle: nil), forCellReuseIdentifier: "CardCell5")
        tableViewMain.register(UINib(nibName: "CardCell11", bundle: nil), forCellReuseIdentifier: "CardCell11")
        tableViewMain.register(UINib(nibName: "CardCell12", bundle: nil), forCellReuseIdentifier: "CardCell12")
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            tableViewMain.register(UINib(nibName: "CellEmpty", bundle: nil), forCellReuseIdentifier: "CellEmpty")
            tableViewRight.register(UINib(nibName: "CellEmpty", bundle: nil), forCellReuseIdentifier: "CellEmpty")
            tableViewRight.register(UINib(nibName: "CardCell5", bundle: nil), forCellReuseIdentifier: "CardCell5")
        }
        
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
            if segue.identifier == "LoadDetailLink" {
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
        
    }
    
    @objc func tapBox(sender: UILongPressGestureRecognizer) {
        if let buttonView = sender.view {
            let existingColor = buttonView.backgroundColor
            if sender.state == .began {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0.1)
            } else if sender.state == .ended {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0)
                if let cell = buttonView.superview?.superview?.superview?.superview as? UITableViewCell {
                    if let indexPath = tableViewMain.indexPath(for: cell) {
                        if(expandedIndexSet.contains(indexPath.row)){
                            expandedIndexSet.remove(indexPath.row)
                            } else {
                                expandedIndexSet.insert(indexPath.row)
                            }
                        self.tableViewMain.reloadRows(at: [indexPath], with: .fade)
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
    

     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            if tableView == tableViewMain {
                
                switch cardContent[indexPath.row].type {
                    
                    case 1:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                        cell.main.attributedText = mainParsed[indexPath.row]
                        if cellOneDIsplayCode {
                            cell.code.text = passedCode
                            cellOneDIsplayCode = false
                        }
                        return cell
                    
                    case 2:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                        cell.main.text = cardContent[indexPath.row].main
                        return cell
                        
                    case 3:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                        cell.main.text = cardContent[indexPath.row].main
                        cell.sub.attributedText = subParsed[indexPath.row]
                        cell.step.text = cardContent[indexPath.row].step
                        return cell
                        
                    case 4:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                        cell.main.attributedText = mainParsed[indexPath.row]
                        cell.step.text = cardContent[indexPath.row].step
                        return cell
                        

                case 11:
                    let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell11") as! CardCell11
                    cell.main.text = cardContent[indexPath.row].main
                    return cell
                    
                case 12:
                    let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell12") as! CardCell12
                    cell.main.text = cardContent[indexPath.row].main
                    return cell
                    
                default:
                    let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CellEmpty") as! CellEmpty
                    tableViewMainHidden.insert(indexPath.row)
                    return cell
                }
                
            } else if tableView == tableViewRight {
                
                switch cardContent[indexPath.row].type {
                case 5,6,7,8,9:
                    let cell = tableViewRight.dequeueReusableCell(withIdentifier: "CardCell5") as! CardCell5
                    switch cardContent[indexPath.row].type {
                    case 5:
                        cell.box.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                        cell.button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0)
                        cell.main.textColor = UIColor.systemOrange
                        cell.arrow.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
                        cell.arrow.tintColor = UIColor.systemOrange
                    case 6:
                        cell.box.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
                        cell.button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0)
                        cell.main.textColor = UIColor.systemBlue
                        cell.arrow.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                        cell.arrow.tintColor = UIColor.systemBlue
                    case 7:
                        cell.box.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
                        cell.button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0)
                        cell.main.textColor = UIColor.systemGreen
                        cell.arrow.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                        cell.arrow.tintColor = UIColor.systemGreen
                    case 9:
                        cell.box.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.15)
                        cell.button.backgroundColor = UIColor.systemPurple.withAlphaComponent(0)
                        cell.main.textColor = UIColor.systemPurple
                        cell.arrow.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
                        cell.arrow.tintColor = UIColor.systemPurple
                    default:
                        cell.box.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
                        cell.button.backgroundColor = UIColor.systemGray.withAlphaComponent(0)
                        cell.main.textColor = UIColor.label
                        cell.arrow.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
                        cell.arrow.tintColor = UIColor.label
                    }
                    
                    cell.main.text = cardContent[indexPath.row].main
                    cell.sub.delegate = self
                    

                        cell.arrow.image = nil
                        cell.arrow.backgroundColor = UIColor.clear
                        cell.sub.attributedText = subParsed[indexPath.row]
                        cell.sub0.isActive = false
                        cell.sub8.isActive = true
                        if cell.subheight?.isActive != nil {
                            cell.subheight.isActive = false
                        }
                    return cell
                    

                default:
                    let cell = tableViewRight.dequeueReusableCell(withIdentifier: "CellEmpty") as! CellEmpty
                    tableViewRightHidden.insert(indexPath.row)
                    return cell
                }
                
                
                
            } else {
                fatalError("Table not present")
            }
            
            
            
            
            
        } else {

        
        switch cardContent[indexPath.row].type {
            
            case 1:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.main.attributedText = mainParsed[indexPath.row]
                if cellOneDIsplayCode {
                    cell.code.text = passedCode
                    cellOneDIsplayCode = false
                }
                return cell
            
            case 2:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            case 3:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                cell.main.text = cardContent[indexPath.row].main
                cell.sub.attributedText = subParsed[indexPath.row]
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 4:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                cell.main.attributedText = mainParsed[indexPath.row]
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 5,6,7,8,9:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell5") as! CardCell5
                switch cardContent[indexPath.row].type {
                case 5:
                    cell.box.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
                    cell.button.backgroundColor = UIColor.systemOrange.withAlphaComponent(0)
                    cell.main.textColor = UIColor.systemOrange
                    cell.arrow.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
                    cell.arrow.tintColor = UIColor.systemOrange
                case 6:
                    cell.box.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
                    cell.button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0)
                    cell.main.textColor = UIColor.systemBlue
                    cell.arrow.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                    cell.arrow.tintColor = UIColor.systemBlue
                case 7:
                    cell.box.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
                    cell.button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0)
                    cell.main.textColor = UIColor.systemGreen
                    cell.arrow.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                    cell.arrow.tintColor = UIColor.systemGreen
                case 9:
                    cell.box.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.15)
                    cell.button.backgroundColor = UIColor.systemPurple.withAlphaComponent(0)
                    cell.main.textColor = UIColor.systemPurple
                    cell.arrow.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
                    cell.arrow.tintColor = UIColor.systemPurple
                default:
                    cell.box.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
                    cell.button.backgroundColor = UIColor.systemGray.withAlphaComponent(0)
                    cell.main.textColor = UIColor.label
                    cell.arrow.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
                    cell.arrow.tintColor = UIColor.label
                }
                
                cell.main.text = cardContent[indexPath.row].main
                cell.sub.delegate = self
                
                let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(tapBox))
                tapGesture.minimumPressDuration = 0
                cell.button.addGestureRecognizer(tapGesture)

                if expandedIndexSet.contains(indexPath.row) {
                    cell.arrow.image = UIImage(systemName: "arrow.up")
                    cell.sub.attributedText = subParsed[indexPath.row]
                    cell.sub0.isActive = false
                    cell.sub8.isActive = true
                    if cell.subheight?.isActive != nil {
                        cell.subheight.isActive = false
                    }
                } else {
                    cell.arrow.image = UIImage(systemName: "arrow.down")
                    cell.sub.attributedText = nil
                    cell.sub8.isActive = false
                    cell.sub0.isActive = true
                    if cell.subheight?.isActive != nil {
                        cell.subheight.isActive = true
                    }
                }
                return cell
                
            case 11:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell11") as! CardCell11
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            case 12:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell12") as! CardCell12
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            default:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.main.text = cardContent[indexPath.row].main
                return cell
            
        }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if tableView == tableViewMain {
                if tableViewMainHidden.contains(indexPath.row) {
                    return 0
                } else {
                    return UITableView.automaticDimension
                }
            } else if tableView == tableViewRight {
                if tableViewRightHidden.contains(indexPath.row) {
                    return 0
                } else {
                    return UITableView.automaticDimension
                }
            } else {
                return UITableView.automaticDimension
            }
        } else {
        return UITableView.automaticDimension
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
            
            tableViewMain.reloadData()
            if UIDevice.current.userInterfaceIdiom == .pad {
                tableViewRight.reloadData()
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        scrubLink = URL.absoluteString
        let regex = try! NSRegularExpression(pattern: "[1-4][-][0-9]")
//        let phoneRegex = try! NSRegularExpression(pattern: "0[0-9]{10}")
        let range = NSRange(location: 0, length: scrubLink.count)
        if regex.firstMatch(in: scrubLink, options: [], range: range) != nil {
        self.performSegue(withIdentifier: "LoadDetailLink", sender: self)
        return false
        } else  {
            UIApplication.shared.open(URL)
            return false
        }
    }
    


    func parseHtmlAttributes(htmlText: String) -> NSMutableAttributedString {
    
    let htmlInput = """
                    <style type=\"text/css\">
                    body {
                        font-family: -apple-system, 'HelveticaNeue';
                        font-size: 15;
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
    
    let attrStr = try! NSMutableAttributedString(
        data: htmlInput.data(using: String.Encoding.utf8)!,
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
        let stringRange = match.range
        let stringLink = (unwrapped as NSString).substring(with: stringRange)
        let scrubLink = stringLink.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "→", with: "").replacingOccurrences(of: " ", with: "")
        let scrubURL = NSURL(string: scrubLink)!
        attrStr.addAttribute(NSAttributedString.Key.link, value: scrubURL, range: match.range)
        attrStr.addAttribute(NSAttributedString.Key.underlineStyle , value: NSUnderlineStyle.single.rawValue, range: match.range)
    }
    return attrStr
}
}

