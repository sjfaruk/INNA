//
//  CustomTabBarController.swift
//  Inna
//
//  Created by MOSHIOUR on 5/21/18.
//  Copyright © 2018 moshiour. All rights reserved.
//

import UIKit

class CustomTabBarController: UITabBarController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        let friendsController = MessagesController(collectionViewLayout: layout)
        
    }
}
