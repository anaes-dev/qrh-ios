//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit
import SwiftyJSON

class GuidelinesController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    
    var guidelines = [[String : AnyObject]]()
    var filteredGuidelines = [[String : AnyObject]]()
    var passCode: String?
    var passTitle: String?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchGuidelineList()
        filteredGuidelines = guidelines
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filteredGuidelines.count
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GuidelinesCell") as? GuidelinesCell else { return UITableViewCell() }
            let iP = filteredGuidelines[indexPath.row]
            let versionText = "v.\(iP["version"]!)"
            cell.title.text = iP["title"] as? String
            cell.code.text = iP["code"] as? String
            cell.version.text = versionText
            return cell
    }
      
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let iP = filteredGuidelines[indexPath.row]
        passCode = iP["code"] as? String
        passTitle = iP["title"] as? String
        self.performSegue(withIdentifier: "LoadDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? GuidelineDetail {
            destination.passedCode = passCode!
            destination.passedTitle = passTitle!
        }
           
    }
    
    func fetchGuidelineList() {
        let url = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
        let fileContents = try! Data(contentsOf: url)
        let jsonData1 = try! JSON(data: fileContents)
        let jsonData2 = jsonData1["guidelines"].arrayObject
        self.guidelines = jsonData2 as! [[String : AnyObject]]
        tableView.reloadData()
    }
     
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.lowercased()
        print(searchText)

        tableView.reloadData()
    }
}
