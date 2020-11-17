//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit


class DetailController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
//    Tableview outlets
    
    @IBOutlet weak var tableViewMain: UITableView!
    @IBOutlet weak var tableViewRight: UITableView!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    
    
//    Breadcrumb outlets
    
    @IBOutlet var breadcrumbStack: UIStackView!
    @IBOutlet var breadcrumbScroll: UIScrollView!
    @IBOutlet var breadcrumb: UIView!
    @IBOutlet var bcGradientLeft: UIView!
    @IBOutlet var bcGradientRight: UIView!
    
    
    //    Codable structures
    
    struct Card: Codable {
        var type: Int
        var head: String
        var body: String
        var step: String
    }
    
    struct Cards: Codable {
        var DetailContent: [Card]
    }
        
    var cardContent = [Card]()
    
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
    
    
//    Init variables
    
    var passedCode = String()
    var passedTitle = String()
    var passedURL = String()
    var scrubLink = String()
    var fetchedURL: String = ""
    var fetchedTitle: String = "Default"

    var bodyParsed = Array<NSMutableAttributedString>()
    
    var expandedIndexSet : IndexSet = []
    var tableViewMainHidden : IndexSet = []
    var tableViewRightHidden : IndexSet = []
    
    var breadcrumbPopulated: Bool = Bool()
    
    lazy var largeTitleFrame: CGRect = {
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController.navigationBar.frame
    }()
    
    
//    viewDidLoad
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activitySpinner.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
        
//      Load cells for table
        
        tableViewMain.register(UINib(nibName: "CardCell1", bundle: nil), forCellReuseIdentifier: "CardCell1")
        tableViewMain.register(UINib(nibName: "CardCell2", bundle: nil), forCellReuseIdentifier: "CardCell2")
        tableViewMain.register(UINib(nibName: "CardCell3", bundle: nil), forCellReuseIdentifier: "CardCell3")
        tableViewMain.register(UINib(nibName: "CardCell4", bundle: nil), forCellReuseIdentifier: "CardCell4")
        tableViewMain.register(UINib(nibName: "CardCell5", bundle: nil), forCellReuseIdentifier: "CardCell5")
        tableViewMain.register(UINib(nibName: "CardCell10", bundle: nil), forCellReuseIdentifier: "CardCell10")
        tableViewMain.register(UINib(nibName: "CardCell11", bundle: nil), forCellReuseIdentifier: "CardCell11")
        tableViewMain.register(UINib(nibName: "CardCell12", bundle: nil), forCellReuseIdentifier: "CardCell12")
        
//        Load cells needed for iPad layout
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            tableViewMain.register(UINib(nibName: "CellEmpty", bundle: nil), forCellReuseIdentifier: "CellEmpty")
            tableViewRight.register(UINib(nibName: "CellEmpty", bundle: nil), forCellReuseIdentifier: "CellEmpty")
            tableViewRight.register(UINib(nibName: "CardCell5", bundle: nil), forCellReuseIdentifier: "CardCell5")
        }
        
//        Pull JSON from file corresponding with code passed to view
        
        let jsonURL = Bundle.main.url(forResource: passedCode, withExtension: "json")!
        if let jsonDATA = try? Data(contentsOf: jsonURL) {
           parseCards(json: jsonDATA)
        }
        
//        Set button for loading PDF
        
        let pdfButton = UIBarButtonItem(image: UIImage(systemName: "arrow.down.doc"), style: .plain, target: self, action: #selector(loadPDF))
        navigationItem.rightBarButtonItem = pdfButton
        
//        Set title & back button from title passed to view
        
        navigationItem.title = passedTitle
        navigationItem.backButtonTitle = passedTitle
       
//        Add breadcrumbs if more than 2 viewcontrollers deep in navigation stack

        if ((navigationController?.viewControllers.count)! > 2) {
            populateBreadCrumb()
        }
    
//      Load table data
        
        tableViewMain.reloadData()
        if (UIDevice.current.userInterfaceIdiom) == .pad {
            tableViewRight.reloadData()
        }
        
//      Stop loading spinner
              
        activitySpinner.stopAnimating()
    
    }
    
   
//    Return to large title after rotation change back to portrait
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            if UIDevice.current.orientation == .portrait {
                navigationController?.navigationBar.frame = largeTitleFrame
            }
        }
    

//    Setup breadcrumb
    
    func populateBreadCrumb() {
        if !breadcrumbPopulated {
            if var vcarray: Array<UIViewController> = self.navigationController?.viewControllers {
                
//                Add home button
                
                let homeButton = BreadcrumbButton()
                homeButton.formatBc()
                homeButton.homeBc()
                homeButton.addTarget(self, action: #selector(homePop), for: .touchUpInside)
                breadcrumbStack.addArrangedSubview(homeButton)
                
                
//                Remove bottom viewcontroller (Home) then loop remaining in stack, add button for each
                
                vcarray.removeFirst()
                
                for (index, vc) in vcarray.enumerated() {
                    let bcButton = BreadcrumbButton()
                    bcButton.formatBc()
                    bcButton.chevronBc(title: vc.navigationItem.title!, index: index)
                    bcButton.addTarget(self, action: #selector(breadcrumbPop), for: .touchUpInside)
                    breadcrumbStack.addArrangedSubview(bcButton)
                }
                
//                Breadcrumb frame size and constraints

                breadcrumb.frame.size.height = 32
                breadcrumbStack.layoutIfNeeded()
                breadcrumbScroll.layoutIfNeeded()
                
                self.tableViewMain.tableHeaderView = breadcrumb
                
                breadcrumb.translatesAutoresizingMaskIntoConstraints = false
                breadcrumb.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
                breadcrumb.topAnchor.constraint(equalTo: tableViewMain.topAnchor).isActive = true
                breadcrumb.heightAnchor.constraint(equalToConstant: 32).isActive = true
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    breadcrumb.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6, constant: -8).isActive = true
                } else {
                    breadcrumb.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
                }
                
                
//                Scroll to right of scrollview to show nearest viewcontrollers
                
                if (breadcrumbScroll.contentSize.width) > breadcrumb.frame.width {
                    if (UIDevice.current.userInterfaceIdiom == .pad) {
                        let rightOffset = CGPoint(x: (breadcrumbScroll.contentSize.width) - (view.safeAreaLayoutGuide.layoutFrame.width * 0.6) + 8, y: 0);
                        breadcrumbScroll.setContentOffset(rightOffset, animated: false)
                    } else {
                        let rightOffset = CGPoint(x: (breadcrumbScroll.contentSize.width) - view.safeAreaLayoutGuide.layoutFrame.width, y: 0);
                        breadcrumbScroll.setContentOffset(rightOffset, animated: false)
                    }
                }
                
//                Add gradient overlays on either side of breadcrumb frame
                
                let gradLeft = CAGradientLayer()
                gradLeft.frame.size = bcGradientLeft.frame.size
                gradLeft.colors = [UIColor.systemGray6.withAlphaComponent(1).cgColor, UIColor.systemGray6.withAlphaComponent(0).cgColor]
                gradLeft.startPoint = CGPoint(x: 0.2, y: 0.5)
                gradLeft.endPoint = CGPoint(x: 1, y: 0.5)
                bcGradientLeft.layer.addSublayer(gradLeft)
                
                let gradRight = CAGradientLayer()
                gradRight.frame.size = bcGradientRight.frame.size
                gradRight.colors = [UIColor.systemGray6.withAlphaComponent(1).cgColor, UIColor.systemGray6.withAlphaComponent(0).cgColor]
                gradRight.startPoint = CGPoint(x: 0.8, y: 0.5)
                gradRight.endPoint = CGPoint(x: 0, y: 0.5)
                bcGradientRight.layer.addSublayer(gradRight)

            }
            breadcrumbPopulated = true
        }
    }
    
//    Breadcrumb button actions
    
    @objc func breadcrumbPop(sender: UIButton) {
        if let vcPop = self.navigationController?.viewControllers[sender.tag] {
            self.navigationController?.popToViewController(vcPop, animated: true)
        }
    }
    
    @objc func homePop(sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
        
//    Tableview setup

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cardContent.count
    }
    
    
//    Segue actions
    
    @objc func loadPDF(sender: AnyObject) {
        self.performSegue(withIdentifier: "LoadPDF", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        PDF segue
        
        if let destination = segue.destination as? PDFNavController {
            destination.passedURL = passedURL
        }
        
        
//        Link to other guideline segue
        
        if let destination = segue.destination as? DetailController {
            if segue.identifier == "LoadDetailLink" || segue.identifier == "LoadDetailLinkTablet" {
                
//          Currently reloads and filters guidelines.json to find title, code & URL to pass to new instance of view controller - ? more optimal way to achieve this
                
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
                self.activitySpinner.stopAnimating()
                if(view.isUserInteractionEnabled == false) {
                    view.isUserInteractionEnabled = true
                }
                
            }
            
        }
    }
    
    
//    Gesture actions for expanding boxes
    
    @objc func tapBox(sender: UILongPressGestureRecognizer) {
        if let buttonView = sender.view {
            
//            Find existing colour of button
            
            let existingColor = buttonView.backgroundColor
            
//            Darken button if gesture began
            if sender.state == .began {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0.1)
                
//            Action if gesture completed
            } else if sender.state == .ended {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0)
                
//                Find index of parent cell and add/remove from expanded set
                if let cell = buttonView.superview?.superview?.superview?.superview as? UITableViewCell {
                    if let indexPath = tableViewMain.indexPath(for: cell) {
                        if(expandedIndexSet.contains(indexPath.row)){
                            expandedIndexSet.remove(indexPath.row)
                            } else {
                                expandedIndexSet.insert(indexPath.row)
                            }
                        
//                        Reload modified cell only with fade animation
                        self.tableViewMain.reloadRows(at: [indexPath], with: .fade)
                        return
                    }
                }
                
//                Action if gesture cancelled
            } else if sender.state == .cancelled {
                buttonView.backgroundColor = existingColor?.withAlphaComponent(0)
                return
            
        }
        } else {
            return
        }
    }
    

//    Populate table...
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

//      Different setup if iPad:
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
//            Populate main table (left) - 60% width, all cards except callout boxes
            
            if tableView == tableViewMain {
                
                switch cardContent[indexPath.row].type {
                    
                    case 1:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                        cell.body.attributedText = bodyParsed[indexPath.row]
                        cell.body.delegate = self
//                      Used for more than introduction cell in some guidelines: only put code in top right of first cell
                        if indexPath.row == 0 {
                            cell.code.text = passedCode
                        }
                        return cell
                    
                    case 2:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                        cell.label.attributedText = bodyParsed[indexPath.row]
//                        Override attributed text color (assigned label color when html parsed)
                        cell.label.textColor = UIColor.systemBackground
                        return cell
                        
                    case 3:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                        cell.head.text = cardContent[indexPath.row].head
                        cell.body.attributedText = bodyParsed[indexPath.row]
                        cell.step.text = cardContent[indexPath.row].step
                        cell.body.delegate = self
                        return cell
                        
                    case 4:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                        cell.body.attributedText = bodyParsed[indexPath.row]
                        cell.step.text = cardContent[indexPath.row].step
                        cell.body.delegate = self
                        // Fix for guideline 3-5 auto link misdetection
                        if(passedCode == "3-5" && indexPath.row == 7 || passedCode == "3-9" && indexPath.row == 8) {
                            cell.body.linkTextAttributes = nil
                            cell.body.isSelectable = false
                        }
                        return cell

                    case 11:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell11") as! CardCell11
                        cell.label.text = cardContent[indexPath.row].body
                        return cell
                        
                    case 12:
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell12") as! CardCell12
                        cell.label.text = cardContent[indexPath.row].head
                        return cell
                        
                    default:
//                        This is a bit of a fudge to hide certain items as zero-height empty cells, but keeps cell indices consistent & avoids having to generate & hold multiple arrays of filtered cells
                        let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CellEmpty") as! CellEmpty
                        tableViewMainHidden.insert(indexPath.row)
                        return cell
                }
            
                
//            Populate right table - 40% width, all callout boxes, non-expanding
                
            } else if tableView == tableViewRight {
                
                switch cardContent[indexPath.row].type {
                
//                Image cell
                
                case 10:
                    let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell10") as! CardCell10
                    cell.head.text = cardContent[indexPath.row].head
                    let imageView = cell.imageFile as UIImageView
                    if let imageFile = UIImage(named: cardContent[indexPath.row].body) {
                        imageView.image = imageFile
//                        Workaround for height bug - for some reason works best referencing screen width rather than parent container
                        let ratio = imageFile.size.width / imageFile.size.height
                        let newHeight = (UIScreen.main.bounds.width * 0.4) / ratio
                        cell.imageHeight.constant = newHeight
                    }
                    return cell
                    
                    
                case 5,6,7,8,9:
                    let cell = tableViewRight.dequeueReusableCell(withIdentifier: "CardCell5") as! CardCell5
                                        
//                    Adjust colors according to cell type
                    
                    cell.boxCol(type: cardContent[indexPath.row].type)
                    
                    cell.head.text = cardContent[indexPath.row].head
                    cell.body.delegate = self
                    cell.body.attributedText = bodyParsed[indexPath.row]
                    
                    // Fix for guideline 2-5 auto link misdetection
                    if(passedCode == "2-5" && indexPath.row == 12) {
                            cell.body.linkTextAttributes = nil
                            cell.body.isSelectable = false
                    }
                    
//                    Fixed / non-expanding boxes, therefore arrow hidden & expanded constraints active

                    cell.arrow.image = nil
                    cell.arrow.backgroundColor = UIColor.clear
                    cell.sub0.isActive = false
                    cell.sub8.isActive = true
                    if cell.subheight?.isActive != nil {
                        cell.subheight.isActive = false
                    }
                    
                    return cell
                    

                default:
//                  This is a bit of a fudge to hide certain items as zero-height empty cells, but keeps cell indices consistent & avoids having to generate & hold multiple arrays of filtered cells
                    let cell = tableViewRight.dequeueReusableCell(withIdentifier: "CellEmpty") as! CellEmpty
                    tableViewRightHidden.insert(indexPath.row)
                    return cell
                }
                
                
                
            } else {
//                Should never be called but should save from fatal error
                let cell = tableView.dequeueReusableCell(withIdentifier: "CellEmpty") as! CellEmpty
                return cell
            }
            
        } else {

        
//        Populate table on non-iPad:
        
        switch cardContent[indexPath.row].type {
            
            case 1:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.body.attributedText = bodyParsed[indexPath.row]
                cell.body.delegate = self
//               Used for more than introduction cell in some guidelines: only put code in top right of first cell
                if indexPath.row == 0 {
                    cell.code.text = passedCode
                }
                return cell
            
            case 2:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                cell.label.attributedText = bodyParsed[indexPath.row]
                cell.label.textColor = UIColor.systemBackground
                return cell
                
            case 3:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                cell.head.text = cardContent[indexPath.row].head
                cell.body.attributedText = bodyParsed[indexPath.row]
                cell.step.text = cardContent[indexPath.row].step
                cell.body.delegate = self
                return cell
                
            case 4:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                cell.body.attributedText = bodyParsed[indexPath.row]
                cell.step.text = cardContent[indexPath.row].step
                cell.body.delegate = self
                // Fix for guideline 3-5 auto link misdetection
                if(passedCode == "3-5" && indexPath.row == 7 || passedCode == "3-9" && indexPath.row == 8) {
                    cell.body.linkTextAttributes = nil
                    cell.body.isSelectable = false
                }
                return cell
                
            case 5,6,7,8,9:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell5") as! CardCell5
                
//                Set colors by card type
                
                cell.boxCol(type: cardContent[indexPath.row].type)

                cell.head.text = cardContent[indexPath.row].head
                cell.body.delegate = self
                
                // Fix for guideline 2-5 auto link misdetection
                if(passedCode == "2-5" && indexPath.row == 12) {
                        cell.body.linkTextAttributes = nil
                        cell.body.isSelectable = false
                }
                
//                Add gesture recogniser to button (UIView covering title & arrow)
                
                let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(tapBox))
                tapGesture.minimumPressDuration = 0
                cell.button.addGestureRecognizer(tapGesture)
                
//                Change view depending on expanded state

                if expandedIndexSet.contains(indexPath.row) {
                    cell.arrow.image = UIImage(systemName: "arrow.up")
                    cell.body.attributedText = bodyParsed[indexPath.row]
                    cell.sub0.isActive = false
                    cell.sub8.isActive = true
                   if cell.subheight?.isActive != nil {
                        cell.subheight.isActive = false
                    }
                } else {
                    cell.arrow.image = UIImage(systemName: "arrow.down")
                    cell.body.attributedText = nil
                    cell.sub8.isActive = false
                    cell.sub0.isActive = true
                    if cell.subheight?.isActive != nil {
                        cell.subheight.isActive = true
                    }
                }
                return cell
                
            case 10:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell10") as! CardCell10
                cell.head.text = cardContent[indexPath.row].head
                let imageView = cell.imageFile as UIImageView
                if let imageFile = UIImage(named: cardContent[indexPath.row].body) {
                    imageView.image = imageFile
//                  Workaround for height bug - for some reason works best referencing screen width rather than parent container
                    let ratio = imageFile.size.width / imageFile.size.height
                    let newHeight = UIScreen.main.bounds.width / ratio
                    cell.imageHeight.constant = newHeight
                }
                return cell
                
            case 11:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell11") as! CardCell11
                cell.label.text = cardContent[indexPath.row].body
                return cell
                
            case 12:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell12") as! CardCell12
                cell.label.text = cardContent[indexPath.row].head
                return cell
                
            default:
                let cell = tableViewMain.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.body.text = cardContent[indexPath.row].body
                return cell
            
        }
        }
    }
    
    
//    Workaround for zero-height empty cells on iPad (justification above)
    
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
    
    
//    Populate codables from JSON
    
    func parseCards(json: Data) {
        let decoder = JSONDecoder()
        if let jsonCards = try? decoder.decode(Cards.self, from: json) {
            cardContent = jsonCards.DetailContent
            
            for card in cardContent {
                bodyParsed.append(parseHtmlAttributes(htmlText: card.body))
            }
        }
    }

    

//    Perform segue for links between guidelines
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        scrubLink = URL.absoluteString
        let regex = try! NSRegularExpression(pattern: "[1-4][-][0-9]")
        let range = NSRange(location: 0, length: scrubLink.count)
        
//        Perform segue only if link matches format for link to other guideline, otherwise fall back to default behaviour (for URLS & phone numbers)
        if regex.firstMatch(in: scrubLink, options: [], range: range) != nil {
            if let vcCount = self.navigationController?.viewControllers.count {
                if(vcCount < 11) {
                    activitySpinner.startAnimating()
                    if(view.isUserInteractionEnabled == true) {
                        view.isUserInteractionEnabled = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                         
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            self.performSegue(withIdentifier: "LoadDetailLinkTablet", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "LoadDetailLink", sender: self)
                        }
                        
                    }
                } else {
                    let alert = UIAlertController(title: "Too many guidelines open", message: "Please do not try to open more than 10 guidelines", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
            return false
        } else  {
            UIApplication.shared.open(URL)
            return false
        }
    }
    

//    Parse strings to attributed text

    func parseHtmlAttributes(htmlText: String) -> NSMutableAttributedString {
        
//    Fix for html styling
    
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
        
//        Generate attributed string from JSON
    
        let attrStr = try! NSMutableAttributedString(
            data: htmlInput.data(using: String.Encoding.utf8)!,
            options: [.documentType: NSMutableAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
            documentAttributes: nil)

//        Removing trailing whitespace / line break
            
        if let lastCharacter = attrStr.string.last, lastCharacter == "\n" {
            attrStr.deleteCharacters(in: NSRange(location: attrStr.length-1, length: 1))
        }
        
//        Set font color to UIColor.label (otherwise remains black in dark mode)
        
        attrStr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length:attrStr.length))

//        Detect and add links for guidelines
        
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
