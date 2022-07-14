//
//  WDTemperatureViewController.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa
import Combine
import Shared

class WDTemperatureViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    
    var sensors: [WDSensor]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = WDEngine.shared.metricsSubject
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.sensors = metrics?.sensors
            }
    }
    
}

extension WDTemperatureViewController: NSTableViewDelegate {
    
}

extension WDTemperatureViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sensors?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return sensors?[row]
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn,
              let temperature = sensors?[row],
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
