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
    
    var sensors: [WDSensor]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for column in tableView.tableColumns {
            let sortDesc = NSSortDescriptor(key: column.identifier.rawValue, ascending: true)
            column.sortDescriptorPrototype = sortDesc
        }
        
        _ = WDEngine.shared.metricsSubject
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.reload(sensors: metrics?.sensors)
            }
    }
    
    private func reload(sensors: [WDSensor]?) {
        if tableView.sortDescriptors.count > 0 {
            self.sensors = sensors?.sorted(by: { sensor1, sensor2 in
                for sortDesc in tableView.sortDescriptors {
                    var lhs: String?
                    var rhs: String?
                    var options: String.CompareOptions = .literal
                    
                    switch sortDesc.key {
                    case NSUserInterfaceItemIdentifier.name.rawValue:
                        lhs = sensor1.name
                        rhs = sensor2.name
                    case NSUserInterfaceItemIdentifier.temperature.rawValue:
                        lhs = "\(sensor1.value)"
                        rhs = "\(sensor2.value)"
                        options = .numeric
                    default: break
                    }
                    
                    guard let lhs = lhs, let rhs = rhs else {
                        continue
                    }
                    
                    switch lhs.compare(rhs, options: options) {
                    case .orderedSame: continue
                    case .orderedAscending: return sortDesc.ascending
                    case .orderedDescending: return !sortDesc.ascending
                    }
                }
                return true
            })
        } else {
            self.sensors = sensors
        }
        
        tableView.reloadData()
    }
    
}

extension WDTemperatureViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
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

extension WDTemperatureViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sensors?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        reload(sensors: sensors)
    }
    
}

fileprivate extension NSUserInterfaceItemIdentifier {
    static let name = NSUserInterfaceItemIdentifier("name")
    static let temperature = NSUserInterfaceItemIdentifier("temperature")
}
