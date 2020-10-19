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
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//                if(expandedIndexSet.contains(indexPath.row)){
//            expandedIndexSet.remove(indexPath.row)
//        } else {
//            expandedIndexSet.insert(indexPath.row)
//        }
//        tableView.reloadData()
//    }
    
    @objc func tapBox(sender: UITapGestureRecognizer) {
        if let buttonView = sender.view {
            let existingColor = buttonView.backgroundColor
            if sender.state == .ended {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0.1)
            
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2 ) {
                    buttonView.backgroundColor = existingColor?.withAlphaComponent(0)
                }
            }
            if let cell = buttonView.superview?.superview?.superview?.superview as? UITableViewCell {
                if let indexPath = tableView.indexPath(for: cell) {
                    if(expandedIndexSet.contains(indexPath.row)){
                        expandedIndexSet.remove(indexPath.row)
                        } else {
                            expandedIndexSet.insert(indexPath.row)
                        }
                    tableView.reloadRows(at: [indexPath], with: .fade)
                    }
            }

        }
    }
    
    
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch cardContent[indexPath.row].type {
            
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                let mainInput = cardContent[indexPath.row].main
                cell.main.setHTMLFromString(htmlText: mainInput)
                return cell
            
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                let subInput = cardContent[indexPath.row].sub
                cell.sub.setHTMLFromString(htmlText: subInput)
                cell.main.text = cardContent[indexPath.row].main
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                let mainInput = cardContent[indexPath.row].main
                cell.main.setHTMLFromString(htmlText: mainInput)
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 5,6,7,8:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell5") as! CardCell5
                cell.main.text = cardContent[indexPath.row].main
                let subInput = cardContent[indexPath.row].sub
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapBox))
                cell.button.addGestureRecognizer(tapGesture)
                
                if expandedIndexSet.contains(indexPath.row) {
                  // the label can take as many lines it need to display all text
                    cell.sub.setHTMLFromString(htmlText: subInput)
                    cell.sub0.isActive = false
                    cell.sub8.isActive = true
                    cell.arrow.image = UIImage(systemName: "arrow.up")
                } else {
                  // if the cell is contracted
                  // only show first 3 lines
                    cell.sub.text = ""
                    cell.sub8.isActive = false
                    cell.sub0.isActive = true
                    cell.arrow.image = UIImage(systemName: "arrow.down")
                }
                
                return cell
                
            case 9:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell9") as! CardCell9
                let subInput = cardContent[indexPath.row].sub
//                let customLink = ActiveType.custom(pattern: "[(]?[→][\\s]?[1-4][-][0-9]{1,2}[)]?")
//                cell.sub.numberOfLines = 0
//                cell.sub.enabledTypes = [.url, customLink]
//                cell.sub.customColor[customLink] = UIColor.systemBlue
                cell.sub.setHTMLFromString(htmlText: subInput)
                cell.main.text = cardContent[indexPath.row].main
                
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
            tableView.reloadData()
        }
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
                
        self.attributedText = attrStr
                
    }
    
}
