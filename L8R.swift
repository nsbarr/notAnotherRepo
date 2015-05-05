//
//  L8R.swift
//  CameraTutorial
//
//  Created by nick barr on 5/4/15.
//  Copyright (c) 2015 JQ Software. All rights reserved.
//

import Foundation
import CoreData

public class L8R: NSManagedObject {

    @NSManaged public var fireDate: NSDate
    @NSManaged public var imageData: NSData
    
    lazy var objectIDString:String! = {
        self.objectID.URIRepresentation().absoluteString
        }()

}
