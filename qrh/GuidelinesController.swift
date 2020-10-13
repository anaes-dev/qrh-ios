//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit
import SwiftyJSON

class GuidelinesController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var guidelines = [[String : AnyObject]]()
       

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchGuidelineList()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return guidelines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GuidelinesCell") as? GuidelinesCell else { return UITableViewCell() }
        let iP = guidelines[indexPath.row]
        let versionText = "v.\(iP["version"]!)"
        cell.title.text = iP["title"] as? String
        cell.code.text = iP["code"] as? String
        cell.version.text = versionText
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let iP = guidelines[indexPath.row]
        let code = iP["code"] as? String
        print(code!)
    }
    
    func fetchGuidelineList() {
        let url = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
        let fileContents = try! Data(contentsOf: url)
        let jsonData1 = try! JSON(data: fileContents)
        let jsonData2 = jsonData1["guidelines"].arrayObject
        self.guidelines = jsonData2 as! [[String : AnyObject]]
        tableView.reloadData()
    }
    



}
