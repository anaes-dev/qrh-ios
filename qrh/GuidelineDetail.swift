//
//  GuidelineDetail.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit
import SwiftyJSON

private let reuseIdentifier = "Cell"


class GuidelineDetail: UICollectionViewController {
    
    var passedCode = String()
    var passedTitle = String()
    var guidelineDetail = [[String : AnyObject]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
               
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        
        
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
//        let cell1 = "Cell1"
//        collectionView.register(GuidelineCell1.self, forCellWithReuseIdentifier: cell1)
        fetchGuidelineDetail()
        print(passedCode)
        self.navigationItem.title = passedTitle
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }

        // Do any additional setup after loading the view.
    }
    
   

    func fetchGuidelineDetail() {
        let url = Bundle.main.url(forResource: passedCode, withExtension: "json")!
        let fileContents = try! Data(contentsOf: url)
        let jsonData1 = try! JSON(data: fileContents)
        let jsonData2 = jsonData1["DetailContent"].arrayObject
        self.guidelineDetail = jsonData2 as! [[String : AnyObject]]
        self.collectionView?.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return guidelineDetail.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GuidelineListCell", for: indexPath) as! GuidelineListCell
        let iP = guidelineDetail[indexPath.row]
        print(iP["main"])
        cell.MAIN.text = iP["main"] as? String
   
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
