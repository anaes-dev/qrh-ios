//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

class GuidelinesController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
 
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
    
    var passCode: String?
    var passTitle: String?
    var passURL: String?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var noItemsView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        searchController.searchResultsUpdater = self
        self.navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController!.navigationBar.sizeToFit()
        navigationItem.hidesSearchBarWhenScrolling = false
        
        tableView.tableFooterView = UIView()

        let jsonURL = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
        if let jsonDATA = try? Data(contentsOf: jsonURL) {
            parseList(json: jsonDATA)
        }
        filteredGuidelines = unfilteredGuidelines
        
        let aboutButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.organize, target: self, action: #selector(aboutLoad))
        self.navigationItem.rightBarButtonItem = aboutButton
        
    }
    
    @objc func aboutLoad() {
        self.performSegue(withIdentifier: "LoadAbout", sender: self)
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            if filteredGuidelines.count == 0 {
                tableView.backgroundView = noItemsView
            } else {
                tableView.backgroundView = nil
            }
            return filteredGuidelines.count
        } else {
            return unfilteredGuidelines.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GuidelinesCell") as? GuidelinesCell else { return UITableViewCell() }
        if isFiltering {
            let versionText = "v.\(filteredGuidelines[indexPath.row].version)"
            cell.title.text = filteredGuidelines[indexPath.row].title
            cell.code.text = filteredGuidelines[indexPath.row].code
            cell.version.text = versionText
        } else {
            let versionText = "v.\(unfilteredGuidelines[indexPath.row].version)"
            cell.title.text = unfilteredGuidelines[indexPath.row].title
            cell.code.text = unfilteredGuidelines[indexPath.row].code
            cell.version.text = versionText
        }
        return cell
    }
      
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering {
            passCode = filteredGuidelines[indexPath.row].code
            passTitle = filteredGuidelines[indexPath.row].title
            passURL = filteredGuidelines[indexPath.row].url
        } else {
            passCode = unfilteredGuidelines[indexPath.row].code
            passTitle = unfilteredGuidelines[indexPath.row].title
            passURL = filteredGuidelines[indexPath.row].url
        }
        self.performSegue(withIdentifier: "LoadDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailController {
            destination.passedCode = passCode!
            destination.passedTitle = passTitle!
            destination.passedURL = passURL!
        }
           
    }
    
    func parseList(json: Data) {
        let decoder = JSONDecoder()
        if let jsonGuidelines = try? decoder.decode(GuidelineList.self, from: json) {
            unfilteredGuidelines = jsonGuidelines.guidelines
            tableView.reloadData()
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredGuidelines = unfilteredGuidelines.filter { (guideline: Guideline) -> Bool in
            return guideline.title.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
}

extension GuidelinesController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
      }
    }
