//
//  WDTemperatureViewController.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa
import Combine

class WDTemperatureViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    
    var snapshot: WDSnapshot? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = WDEngine.shared.snapshotSubject
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
    }
    
}

extension WDTemperatureViewController: NSTableViewDelegate {
    
}

extension WDTemperatureViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return snapshot?.temperatures?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return snapshot?.temperatures?[row]
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn,
              let temperature = snapshot?.temperatures?[row],
              let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView else {
            return nil
        }
        
        switch tableColumn.identifier {
        case .name:
            cell.textField?.stringValue = temperature.name
        case .temperature:
            cell.textField?.stringValue =
                String(format: "%.2f℃", temperature.value)
        default: break
        }
    
        return cell
    }
    
}

fileprivate extension NSUserInterfaceItemIdentifier {
    static let name = NSUserInterfaceItemIdentifier("name")
    static let temperature = NSUserInterfaceItemIdentifier("temperature")
}
