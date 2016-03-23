//
//  TaskItem.swift
//  Taskability
//
//  Created by Connor Krupp on 21/03/2016.
//  Copyright © 2016 Connor Krupp. All rights reserved.
//

import Foundation
import CoreData

@objc(TaskItem)
public class TaskItem: NSManagedObject {

    @NSManaged var title: String!
    @NSManaged var isComplete: NSNumber!
    @NSManaged var creationDate: NSDate!
    @NSManaged var subtitle: String?
    @NSManaged var startDate: NSDate?
    @NSManaged var endDate: NSDate?
    @NSManaged var location: String?
    @NSManaged var taskGroup: TaskGroup?

    static let entityName = "TaskItem"

    public class func insertTaskItemWithTitle(title: String, inTaskGroup taskGroup: TaskGroup, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> TaskItem {

        let item = NSEntityDescription.insertNewObjectForEntityForName(self.entityName, inManagedObjectContext: managedObjectContext) as! TaskItem

        item.title = title
        item.creationDate = NSDate()
        item.isComplete = false
        item.taskGroup = taskGroup
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Error saving TaskGroup")
        }

        return item
    }
}