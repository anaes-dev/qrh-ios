//
//  GuidelineList.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit
import SwiftyJSON

class GuidelineList: UICollectionViewController {

    var guidelines = [[String : AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchGuidelineList()
        
    }
    
    func fetchGuidelineList() {
        let url = Bundle.main.url(forResource: "guidelines", withExtension: "json")!
        let fileContents = try! Data(contentsOf: url)
        let jsonData1 = try! JSON(data: fileContents)
        let jsonData2 = jsonData1["guidelines"].arrayObject
        self.guidelines = jsonData2 as! [[String : AnyObject]]
        self.collectionView?.reloadData()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return guidelines.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GuidelineListCell", for: indexPath) as! GuidelineListCell
        let iP = guidelines[indexPath.row]
        
        cell.TITLE.text = iP["title"] as? String
        
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
    

