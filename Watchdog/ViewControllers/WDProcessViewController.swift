//
//  WDProcessViewController.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa
import Combine
import Shared

class WDProcessViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    
    var processes: [WDProcess]?
    
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
                self?.reload(processes: metrics?.processes)
            }
    }
    
    private lazy var memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()
    
    private func reload(processes: [WDProcess]?) {
        if tableView.sortDescriptors.count > 0 {
            self.processes = processes?.sorted(by: { process1, process2 in
                for sortDesc in tableView.sortDescriptors {
                    var lhs: String?
                    var rhs: String?
                    var options: String.CompareOptions = .literal
                    
                    switch sortDesc.key {
                    case NSUserInterfaceItemIdentifier.name.rawValue:
                        lhs = process1.name
                        rhs = process2.name
                    case NSUserInterfaceItemIdentifier.pid.rawValue:
                        lhs = "\(process1.pid)"
                        rhs = "\(process2.pid)"
                        options = .numeric
                    case NSUserInterfaceItemIdentifier.cpu.rawValue:
                        lhs = "\(process1.cpu)"
                        rhs = "\(process2.cpu)"
                        options = .numeric
                    case NSUserInterfaceItemIdentifier.mem.rawValue:
                        lhs = "\(process1.mem)"
                        rhs = "\(process2.mem)"
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
            self.processes = processes
        }
        
        tableView.reloadData()
    }
                                           
}

extension WDProcessViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn,
              let process = processes?[row],
              let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView else {
            return nil
        }
        
        switch tableColumn.identifier {
        case .name:
            cell.textField?.stringValue = process.name
        case .pid:
            cell.textField?.stringValue = "\(process.pid)"
        case .cpu:
            cell.textField?.stringValue = "\(process.cpu)%"
        case .mem:
            cell.textField?.stringValue = memoryFormatter.string(fromByteCount: process.mem)
        default: break
        }
    
        return cell
    }
    
}

extension WDProcessViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return processes?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        reload(processes: processes)
    }
    
}

fileprivate extension NSUserInterfaceItemIdentifier {
    static let name = NSUserInterfaceItemIdentifier("name")
    static let pid = NSUserInterfaceItemIdentifier("pid")
    static let cpu = NSUserInterfaceItemIdentifier("cpu")
    static let mem = NSUserInterfaceItemIdentifier("mem")
}
