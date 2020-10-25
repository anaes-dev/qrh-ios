//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit
import Toast

class GuidelinesController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate {
 
    
//    Setup codables
    
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
    
    var passCode: String?
    var passTitle: String?
    var passURL: String?
    
    var alreadyLaunched: Bool = false
    
    
//    Setup search
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
    
    
//    Table & view outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var noItemsView: UIView!
    
   

    
//    viewDidLoad
    
    override func viewDidLoad() {
               
        
//        Setup navbar & search
        
        searchController.searchResultsUpdater = self
        self.navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController!.navigationBar.sizeToFit()
        navigationItem.hidesSearchBarWhenScrolling = false
        
//        Hide empty cells at bottom of table
        
        tableView.tableFooterView = UIView()
        
//        Parse guidelines list from guidelines.json

        let jsonURL = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
        if let jsonDATA = try? Data(contentsOf: jsonURL) {
            parseList(json: jsonDATA)
        }

        
//        Initially populate filteredlist with unfiltered list
        
        filteredGuidelines = unfilteredGuidelines
        
        
//        Add about link to navbar
        
        let aboutButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(aboutLoad))
        self.navigationItem.rightBarButtonItem = aboutButton
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //        Check if disclaimer accepted
                
        
        if !alreadyLaunched {
            let hasAcceptedDisclaimer = UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")
            if !hasAcceptedDisclaimer {
                alreadyLaunched = true
                performSegue(withIdentifier: "LoadDisclaimer", sender: self)
            } else {
                alreadyLaunched = true
                var toastStyle = ToastStyle()
                toastStyle.messageFont = UIFont.systemFont(ofSize: 10)
                toastStyle.backgroundColor = UIColor.label.withAlphaComponent(0.6)
                toastStyle.messageColor = UIColor.systemBackground
                toastStyle.displayShadow = true
                toastStyle.fadeDuration = 0.4
                toastStyle.maxWidthPercentage = 0.9
                toastStyle.shadowOpacity = 0.6
                toastStyle.shadowColor = UIColor.systemGray
                let toastMessage = """
                    Unofficial adaptation of Quick Reference Handbook
                    Not endorsed by the Association of Anaesthetists
                    Untested and unregulated; not recommended for clinical use
                    No guarantees of completeness, accuracy or performance
                    Should not override your own knowledge and judgement
                    """
                self.view.makeToast(toastMessage, duration: 5.0, position: .bottom, style: toastStyle)
            }
        }
        
    }
    
    
//    Segue to about page
    
    @objc func aboutLoad() {
        self.performSegue(withIdentifier: "LoadAbout", sender: self)
    }
    
    
//    Tableview setup
    
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.hideAllToasts()
    }
    
    
//    Populate table
    
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
      
    
//    Action on selecting table row
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering {
            passCode = filteredGuidelines[indexPath.row].code
            passTitle = filteredGuidelines[indexPath.row].title
            passURL = filteredGuidelines[indexPath.row].url
        } else {
            passCode = unfilteredGuidelines[indexPath.row].code
            passTitle = unfilteredGuidelines[indexPath.row].title
            passURL = unfilteredGuidelines[indexPath.row].url
        }
        tableView.deselectRow(at: indexPath, animated: true)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.performSegue(withIdentifier: "LoadDetailTablet", sender: self)
        } else {
            self.performSegue(withIdentifier: "LoadDetail", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailController {
            destination.passedCode = passCode!
            destination.passedTitle = passTitle!
            destination.passedURL = passURL!
        }
    }
    
    
//    JSON parsing
    
    func parseList(json: Data) {
        let decoder = JSONDecoder()
        if let jsonGuidelines = try? decoder.decode(GuidelineList.self, from: json) {
            unfilteredGuidelines = jsonGuidelines.guidelines
            tableView.reloadData()
        }
    }
    
    
//    Filter from search text
    
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
