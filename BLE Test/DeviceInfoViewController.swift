//
//  DeviceInfoViewController.swift
//  Adafruit Bluefruit LE Connect
//
//  Displays CBPeripheral Services & Characteristics in a UITableView
//
//  Created by Collin Cunningham on 10/24/14.
//  Copyright (c) 2014 Adafruit Industries. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, HelpViewControllerDelegate{
    
    @IBOutlet var tableView:UITableView!
    @IBOutlet var headerView:UIView!
    @IBOutlet var peripheralNameLabel:UILabel!
    @IBOutlet var peripheralUUIDLabel:UILabel!
    @IBOutlet var helpViewController:HelpViewController!
    var delegate:HelpViewControllerDelegate?
//    @IBOutlet var serviceCell:UITableViewCell!
//    @IBOutlet var characteristicCell:UITableViewCell!
    let serviceCellIdentifier = "serviceCell"
    let characteristicCellIdentifier = "characteristicCell"
    var peripheral:CBPeripheral!
    var gattDict:Dictionary<String,String>? //known UUID reference
    var serviceToggle:[Bool]!    //individual ref for service is open in table
    
    convenience init(cbPeripheral:CBPeripheral, delegate:HelpViewControllerDelegate){
        
        //Separate NIBs for iPhone 3.5", iPhone 4", & iPad
        
        var nibName:NSString
        
        if IS_IPHONE{
            nibName = "DeviceInfoViewController_iPhone"
        }
        else{   //IPAD
            nibName = "DeviceInfoViewController_iPad"
        }
        
        self.init(nibName: nibName, bundle: NSBundle.mainBundle())
        
        self.peripheral = cbPeripheral
        self.delegate = delegate
        
        if let path = NSBundle.mainBundle().pathForResource("GATT-characteristics", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, String> {
                self.gattDict = dict
            }
        }
        
        self.serviceToggle = [Bool](count: peripheral.services.count, repeatedValue: false)
        
    }
    
    
//    convenience init(delegate:HelpViewControllerDelegate){  //FOR SCREENSHOTS
//        
//        //Separate NIBs for iPhone 3.5", iPhone 4", & iPad
//        
//        var nibName:NSString
//        
//        if IS_IPHONE{
//            nibName = "DeviceInfoViewController_iPhone"
//        }
//        else{   //IPAD
//            nibName = "DeviceInfoViewController_iPad"
//        }
//        
//        self.init(nibName: nibName, bundle: NSBundle.mainBundle())
//        
//        self.peripheral = CBPeripheral()
//        
//        self.delegate = delegate
//    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.helpViewController.delegate = delegate
        self.title = peripheral.name
        
        let tvc = UITableViewController(style: UITableViewStyle.Plain)
        tvc.tableView = tableView
        
        
        peripheralNameLabel.text = peripheral.name
        peripheralUUIDLabel.text = "UUID: " + peripheral.identifier.UUIDString
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var service = peripheral.services[indexPath.section] as CBService
        var identifier = characteristicCellIdentifier
        var style = UITableViewCellStyle.Subtitle
        var title = ""
        var detailTitle = ""
        var selectable = false
        
        //Service row
        if indexPath.row == 0 {
            identifier = serviceCellIdentifier
//            style = UITableViewCellStyle.Default
            title = displayNameforUUID(service.UUID)
            detailTitle = "Service"
            selectable = true
        }
        
        //Characteristic row
        else {
            let chstc = service.characteristics[indexPath.row-1] as CBCharacteristic
//            let dsctr = chstc.descriptors[0] as CBDescriptor
//            let uuidString = chstc.UUID.UUIDString
            title = displayNameforUUID(chstc.UUID)
            if chstc.value != nil { detailTitle = chstc.value.stringRepresentation() }
            else { detailTitle = "Characteristic" }
        }
        
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
        if (cell == nil) {
            cell = UITableViewCell(style: style, reuseIdentifier: identifier)
        }
        
        //Set up cell
        cell?.textLabel.adjustsFontSizeToFitWidth = true
        cell?.textLabel.minimumScaleFactor = 0.5
        cell?.textLabel.text = title
        cell?.detailTextLabel?.text = detailTitle
        cell?.selectionStyle = UITableViewCellSelectionStyle.None
        cell?.userInteractionEnabled = selectable
        return cell!
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return peripheral.services.count
        
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        if let service = peripheral.services[section] as? CBService {
            
            //service is open/being viewed
            if serviceToggle[section] == true {
                return service.characteristics.count + 1
            }
            //service is closed
            else {
                return 1
            }
            
        }
        
        else {
            return 0
        }
        
    }
    
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.5
    
    }
    
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.5
        
    }
    
    
    func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        
        if indexPath.row == 0 {
            return 0
        }
        else {
            return 2
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let section = indexPath.section
        
        if let charCount = peripheral.services[section].characteristics?.count {
            
            var attributePathArray:[NSIndexPath] = []
            for i in 1...(charCount) {
                attributePathArray.append(NSIndexPath(forRow: i, inSection: indexPath.section))
            }
            
            //make cell background blue
//            tableView.cellForRowAtIndexPath(indexPath)?.backgroundColor = cellSelectionColor
//            let cell = tableView.cellForRowAtIndexPath(indexPath)!
//            UIView.animateWithDuration(0.25, animations: { () -> Void in
//                cell.backgroundColor = UIColor.whiteColor()
//            })
            animateCellSelection(tableView.cellForRowAtIndexPath(indexPath)!)
            
            tableView.beginUpdates()
            if (serviceToggle[section] == true) {
                serviceToggle[section] = false
                tableView.deleteRowsAtIndexPaths(attributePathArray, withRowAnimation: UITableViewRowAnimation.Fade)
            }
            else {
                serviceToggle[section] = true
                tableView.insertRowsAtIndexPaths(attributePathArray, withRowAnimation: UITableViewRowAnimation.Fade)
            }
            tableView.endUpdates()
            
        }
        
        
//        tableView.beginUpdates()
//        tableView.reloadSection(NSIndexSet(indexesInRange: NSMakeRange(section, section)), withRowAnimation: UITableViewRowAnimation.Fade)
//        serviceToggle[section] = !serviceToggle[section]
//        tableView.endUpdates()
    }
    
    
    func helpViewControllerDidFinish(controller : HelpViewController){
        
    }

    
    func displayNameforUUID(uuid:CBUUID)->String {
        
        let uuidString = uuid.UUIDString
        //Check for matching name
        
        //Find description for UUID
        
        //Old method
//        var name:String?
//        for idx in 0...(knownUUIDs.count-1) {
//            if UUIDsAreEqual(uuid, knownUUIDs[idx]) {
//                name = knownUUIDNames[idx]
//                break
//            }
//        }
        //use UUID if no name is found
//        if name == nil {
//            name = uuid.UUIDString
//        }
        
        //New method
        if let name = gattDict?[uuidString] {
            return name
        }
        
        else {
            return uuidString
        }
    }

}
