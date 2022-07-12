//
//  WDMonitorViewController.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa
import SnapKit
import Combine

class WDMonitorViewController: NSViewController {
    
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var toggleSwitch: NSSwitch!
    @IBOutlet weak var typeButton: NSPopUpButton!
    @IBOutlet weak var thresholdField: NSTextField!
    @IBOutlet weak var durationField: NSTextField!
    
    @IBOutlet weak var configurationView: NSBox!
    
    private var strategiesSubscriber: AnyCancellable?
    
    private var strategies: [WDStrategy]? = {
        return WDStrategyManager.shared.strategies
    }()
    
    var selectedStrategy: WDStrategy? {
        didSet {
            if let selectedStrategy = selectedStrategy {
                configurationView.isHidden = false
                toggleSwitch.state = selectedStrategy.enabled ? .on : .off
                typeButton.selectItem(withTitle: selectedStrategy.type.rawValue)
                thresholdField.stringValue = "\(selectedStrategy.threshold)"
                durationField.stringValue = "\(selectedStrategy.duration)"
                segmentedControl.setEnabled(true, forSegment: 1)
            } else {
                configurationView.isHidden = true
                segmentedControl.setEnabled(false, forSegment: 1)
            }
            
            if let row = strategies?.firstIndex(where: { $0.id == selectedStrategy?.id }) {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            } else {
                tableView.selectRowIndexes(IndexSet(integer: -1), byExtendingSelection: false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedStrategy = nil
        
        thresholdField.formatter = {
            let formatter = RangedNumberFormatter(range: 0...100)
            formatter.maximum = 100
            formatter.minimum = 0
            return formatter
        }()
        
        strategiesSubscriber = WDStrategyManager.shared.strategiesSubject
            .sink { [weak self] (strategies) in
                let selectedStrategy = self?.selectedStrategy
                self?.strategies = strategies
                self?.tableView.reloadData()
                self?.selectedStrategy = selectedStrategy
            }
        
        _ = durationField.textDidEndEditingPublisher
            .sink { [weak self] stringValue in
                guard var selectedStrategy = self?.selectedStrategy,
                      let duration = Double(stringValue), duration > 0 else {
                    return
                }
                selectedStrategy.duration = duration
                self?.selectedStrategy = selectedStrategy
                
                WDStrategyManager.shared.update(selectedStrategy)
            }
        
        _ = thresholdField.textDidEndEditingPublisher
            .sink { [weak self] stringValue in
                guard var selectedStrategy = self?.selectedStrategy,
                      let threshold = Double(stringValue), threshold > 0 else {
                    return
                }
                selectedStrategy.threshold = threshold
                self?.selectedStrategy = selectedStrategy
                
                WDStrategyManager.shared.update(selectedStrategy)
            }
    }
    
    @IBAction func segmentedControlDidSelected(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            let selectedStrategy = WDStrategy(UUID().uuidString, .CPU, 60, 45)
            WDStrategyManager.shared.add(selectedStrategy)
            self.selectedStrategy = selectedStrategy
            
        case 1:
            guard let selectedStrategy = selectedStrategy else {
                break
            }
            WDStrategyManager.shared.delete(selectedStrategy)
            self.selectedStrategy = nil
            
        default:
            break
            
        }
    }
    
    @IBAction func toggleSwitchDidSelected(_ sender: NSSwitch) {
        guard var selectedStrategy = selectedStrategy else {
            return
        }
        selectedStrategy.enabled = sender.state == .off ? false : true
        WDStrategyManager.shared.update(selectedStrategy)
    }
    
    @IBAction func typeButtonDidSelected(_ sender: NSPopUpButton) {
        guard var selectedStrategy = selectedStrategy,
              let title = sender.selectedItem?.title,
              let type: WDStrategy.`Type` = .init(rawValue: title)  else {
            return
        }
        selectedStrategy.type = type
        WDStrategyManager.shared.update(selectedStrategy)
    }
    
}

extension WDMonitorViewController: NSTableViewDelegate {
 
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow == -1 {
            selectedStrategy = nil
        } else {
            selectedStrategy = strategies?[tableView.selectedRow]
        }
    }
    
}

extension WDMonitorViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return strategies?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeView(withIdentifier: .titleCell, owner: self) as? NSTableCellView else {
            return nil
        }
        
        cellView.textField?.stringValue = strategies?[row].type.rawValue ?? ""
        
        return cellView
    }
    
}

fileprivate extension NSUserInterfaceItemIdentifier {
    static let titleCell = NSUserInterfaceItemIdentifier("title_cell")
}
