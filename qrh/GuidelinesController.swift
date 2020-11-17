//
//  GuidelinesController.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

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
    var alreadyAnimating: Bool = false
   
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
    @IBOutlet var disclaimerMessage: UIView!
    @IBOutlet weak var disclaimerBackground: UIView!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    
    //    viewDidLoad
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
               
        activitySpinner.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
        disclaimerBackground.backgroundColor = UIColor.label.withAlphaComponent(0.6)

//        Setup navbar & search
        
        searchController.searchResultsUpdater = self
        self.navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.searchTextField.backgroundColor = UIColor.systemBackground
        searchController.searchBar.searchTextField.tintColor = UIColor.systemTeal
        searchController.searchBar.tintColor = UIColor.systemBackground
        definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController!.navigationBar.sizeToFit()
        navigationItem.hidesSearchBarWhenScrolling = false
        
        
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
        
        activitySpinner.stopAnimating()
        
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

                disclaimerMessage.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width - 32, height: disclaimerBackground.frame.size.height + 16)
                disclaimerMessage.center = CGPoint(x: view.bounds.size.width / 2.0, y: (view.bounds.size.height - (disclaimerMessage.frame.size.height / 2.0)) - 64)
                disclaimerMessage.alpha = 0.0
                view.addSubview(disclaimerMessage)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    UIView.animate(withDuration: 0.6, delay: 0, options: .curveLinear, animations: {
                      // 3
                        self.disclaimerMessage.alpha = 1.0
                    }, completion: nil)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    UIView.animate(withDuration: 0.6, delay: 0, options: .curveLinear, animations: {
                      // 3
                        self.disclaimerMessage.alpha = 0.0
                    }, completion: { complete in
                        self.disclaimerMessage.removeFromSuperview()
                    })
                    
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if disclaimerMessage != nil {
            if self.view.subviews.contains(disclaimerMessage) {
                self.disclaimerMessage.removeFromSuperview()
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
        if disclaimerMessage != nil {
            if self.view.subviews.contains(disclaimerMessage) {
                if !alreadyAnimating {
                    alreadyAnimating = true
                    UIView.animate(withDuration: 0.6, delay: 0, options: .curveLinear, animations: {
                      // 3
                        self.disclaimerMessage.alpha = 0.0
                    }, completion: { complete in
                        self.disclaimerMessage.removeFromSuperview()
                    })
                }
            }
        }
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
        
        if disclaimerMessage != nil {
            if self.view.subviews.contains(disclaimerMessage) {
                self.disclaimerMessage.removeFromSuperview()
            }
        }
        

        activitySpinner.startAnimating()
        if(view.isUserInteractionEnabled == true) {
            view.isUserInteractionEnabled = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
        
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.performSegue(withIdentifier: "LoadDetailTablet", sender: self)
            } else {
                self.performSegue(withIdentifier: "LoadDetail", sender: self)
            }
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailController {
            destination.passedCode = passCode!
            destination.passedTitle = passTitle!
            destination.passedURL = passURL!
        }
        self.activitySpinner.stopAnimating()
        if(view.isUserInteractionEnabled == false) {
            view.isUserInteractionEnabled = true
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
