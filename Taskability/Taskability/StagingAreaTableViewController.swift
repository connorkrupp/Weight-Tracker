//
//  StagingAreaTableViewController.swift
//  Taskability
//
//  Created by Connor Krupp on 17/03/2016.
//  Copyright © 2016 Connor Krupp. All rights reserved.
//

import UIKit
import CoreData
import TaskabilityKit

class StagingAreaTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UITextFieldDelegate, StagedTaskTableViewCellDelegate {

    // MARK: Types

    struct MainStoryboard {
        struct CellIdentifiers {
            static let taskCell = "taskCell"
        }
    }


    // MARK: Properties

    @IBOutlet weak var newTaskTextField: UITextField!

    var stagedTaskItems: [TaskItem] {
        return fetchedResultsController.fetchedObjects as! [TaskItem]
    }

    /// Core Data Properties

    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController!

    var managedObjectContext: NSManagedObjectContext {
        return dataController.managedObjectContext
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeFetchedResultsController()

        tableView.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
        tableView.tableFooterView = UIView()

        newTaskTextField.delegate = self
        addNewTaskTextFieldToolbar()
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = fetchedResultsController.sections!
        return sections[section].numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = MainStoryboard.CellIdentifiers.taskCell
        return tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        switch cell {
        case let cell as StagedTaskTableViewCell:
            cell.selectionStyle = .None
            let taskItem = fetchedResultsController.objectAtIndexPath(indexPath) as! TaskItem
            cell.titleLabel.text = taskItem.valueForKey("title") as? String
            cell.isComplete = taskItem.valueForKey("isComplete") as! Bool
            cell.delegate = self
        default:
            fatalError("Unknown cell type")
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
           managedObjectContext.deleteObject(fetchedResultsController.objectAtIndexPath(indexPath) as! TaskItem)
        }
    }

    // MARK: FetchedResultsController

    func initializeFetchedResultsController() {
        let request = NSFetchRequest(entityName: "TaskItem")
        let managedObjectContext = self.dataController.managedObjectContext
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        try! managedObjectContext.save()
        tableView.endUpdates()
    }

    // MARK: StagedTaskTableViewCellDelegate

    func checkmarkTapped(onCell cell: StagedTaskTableViewCell) {
        let indexPath = tableView.indexPathForCell(cell)!
        let taskItem = fetchedResultsController.objectAtIndexPath(indexPath) as! TaskItem
        let completeKey = "isComplete"
        let currentCompleteness = taskItem.valueForKey(completeKey) as! Bool
        taskItem.setValue(!currentCompleteness, forKey: completeKey)
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        TaskItem.insertTaskItemWithTitle(textField.text!, inTaskGroup: nil, inManagedObjectContext: managedObjectContext)
        textField.text = ""
        return true
    }

    // MARK: NewTaskTextField Toolbar Handler

    func addNewTaskTextFieldToolbar() {
        let toolBar = UIToolbar()
        toolBar.barStyle = .Black

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(StagingAreaTableViewController.cancelAddingTasks))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(StagingAreaTableViewController.doneAddingTasks))

        toolBar.tintColor = UIColor.whiteColor()
        toolBar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        toolBar.userInteractionEnabled = true
        toolBar.sizeToFit()

        newTaskTextField.inputAccessoryView = toolBar
    }

    func cancelAddingTasks() {
        newTaskTextField.text = ""
        newTaskTextField.resignFirstResponder()
    }

    func doneAddingTasks() {
        if let newTaskText = newTaskTextField.text {
            if !newTaskText.isEmpty {
                TaskItem.insertTaskItemWithTitle(newTaskText, inTaskGroup: nil, inManagedObjectContext: managedObjectContext)
                newTaskTextField.text = ""
            }
        }
        
        newTaskTextField.resignFirstResponder()
    }
}