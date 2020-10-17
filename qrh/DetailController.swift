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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "CardCell1", bundle: nil), forCellReuseIdentifier: "CardCell1")
        tableView.register(UINib(nibName: "CardCell2", bundle: nil), forCellReuseIdentifier: "CardCell2")
        tableView.register(UINib(nibName: "CardCell3", bundle: nil), forCellReuseIdentifier: "CardCell3")
        tableView.register(UINib(nibName: "CardCell4", bundle: nil), forCellReuseIdentifier: "CardCell4")
        tableView.register(UINib(nibName: "CardCell11", bundle: nil), forCellReuseIdentifier: "CardCell11")
        tableView.register(UINib(nibName: "CardCell12", bundle: nil), forCellReuseIdentifier: "CardCell12")

        
        print(passedCode)
        print(passedTitle)
        
        let jsonURL = Bundle.main.url(forResource: passedCode, withExtension: "json")!
        if let jsonDATA = try? Data(contentsOf: jsonURL) {
           parseCards(json: jsonDATA)
        }
        self.navigationItem.title = passedTitle
        
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cardContent.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch cardContent[indexPath.row].type {
            
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell1") as! CardCell1
                cell.main.text = cardContent[indexPath.row].main
                return cell
            
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell2") as! CardCell2
                cell.main.text = cardContent[indexPath.row].main
                return cell
                
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell3") as! CardCell3
                cell.main.text = cardContent[indexPath.row].main
                cell.sub.text = cardContent[indexPath.row].sub
                cell.step.text = cardContent[indexPath.row].step
                return cell
                
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell4") as! CardCell4
                cell.main.text = cardContent[indexPath.row].main
                cell.step.text = cardContent[indexPath.row].step
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

