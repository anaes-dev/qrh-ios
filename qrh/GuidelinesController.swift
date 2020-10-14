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
        var url: URL
    }
    
    struct GuidelineList: Codable {
        var guidelines: [Guideline]
    }
        
    var unfilteredGuidelines = [Guideline]()
    var filteredGuidelines = [Guideline]()
    
    var passCode: String?
    var passTitle: String?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
    
    @IBOutlet weak var tableView: UITableView!
    
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

        let jsonURL = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
        if let jsonDATA = try? Data(contentsOf: jsonURL) {
            parseList(json: jsonDATA)
        }
        filteredGuidelines = unfilteredGuidelines
        
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
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
        } else {
            passCode = unfilteredGuidelines[indexPath.row].code
            passTitle = unfilteredGuidelines[indexPath.row].title
        }
        self.performSegue(withIdentifier: "LoadDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? GuidelineDetail {
            destination.passedCode = passCode!
            destination.passedTitle = passTitle!
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
