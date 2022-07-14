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
    
    var processes: [WDProcess]? {
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
                self?.processes = metrics?.processes
            }
    }
    
    private lazy var memoryFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()
    
}

extension WDProcessViewController: NSTableViewDelegate {
    
}

extension WDProcessViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return processes?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return processes?[row]
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
        case .pcpu:
            cell.textField?.stringValue = "\(process.cpu)%"
        case .mem:
            cell.textField?.stringValue = memoryFormatter.string(fromByteCount: process.mem)
        default: break
        }
    
        return cell
    }
    
}

fileprivate extension NSUserInterfaceItemIdentifier {
    static let name = NSUserInterfaceItemIdentifier("name")
    static let pid = NSUserInterfaceItemIdentifier("pid")
    static let pcpu = NSUserInterfaceItemIdentifier("cpu")
    static let mem = NSUserInterfaceItemIdentifier("mem")
}
