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

    private var cancellables = Set<AnyCancellable>()

    private lazy var strategies: [WDStrategy]? = {
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
            
            if let selectedStrategy = selectedStrategy, let row = strategies?.firstIndex(of: selectedStrategy) {
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
        
        WDStrategyManager.shared.strategiesSubject
            .sink { [weak self] (strategies) in
                let selectedStrategy = self?.selectedStrategy
                self?.strategies = strategies
                self?.tableView.reloadData()
                self?.selectedStrategy = selectedStrategy
            }
            .store(in: &cancellables)
        
        segmentedControl.selectedSegmentPublisher
            .sink(receiveValue: { [weak self] selectedSegment in
                switch selectedSegment {
                case 0:
                    let selectedStrategy = WDStrategy(UUID().uuidString, .CPU, 60, 45)
                    WDStrategyManager.shared.add(selectedStrategy)
                    self?.selectedStrategy = selectedStrategy
                    
                case 1:
                    guard let selectedStrategy = self?.selectedStrategy else {
                        break
                    }
                    let nextStrategy = self?.strategies?.next(of: selectedStrategy) ?? self?.strategies?.previous(of: selectedStrategy)
                    WDStrategyManager.shared.delete(selectedStrategy)
                    self?.selectedStrategy = nextStrategy
                    
                default:
                    break
                    
                }
            })
            .store(in: &cancellables)
        
        toggleSwitch.statePublisher
            .sink(receiveValue: { [weak self] state in
                guard var selectedStrategy = self?.selectedStrategy else {
                    return
                }
                selectedStrategy.enabled = state == .off ? false : true
                WDStrategyManager.shared.update(selectedStrategy)
            })
            .store(in: &cancellables)
        
        typeButton.selectedItemPublisher
            .sink(receiveValue: { [weak self] menuItem in
                guard var selectedStrategy = self?.selectedStrategy,
                      let title = menuItem?.title,
                      let type: WDStrategy.`Type` = .init(rawValue: title)  else {
                    return
                }
                selectedStrategy.type = type
                WDStrategyManager.shared.update(selectedStrategy)
            })
            .store(in: &cancellables)
        
        durationField.textDidEndEditingPublisher
            .sink { [weak self] stringValue in
                guard var selectedStrategy = self?.selectedStrategy,
                      let duration = Double(stringValue), duration > 0 else {
                    return
                }
                selectedStrategy.duration = duration
                self?.selectedStrategy = selectedStrategy
                
                WDStrategyManager.shared.update(selectedStrategy)
            }
            .store(in: &cancellables)
        
        thresholdField.textDidEndEditingPublisher
            .sink { [weak self] stringValue in
                guard var selectedStrategy = self?.selectedStrategy,
                      let threshold = Double(stringValue), threshold > 0 else {
                    return
                }
                selectedStrategy.threshold = threshold
                self?.selectedStrategy = selectedStrategy
                
                WDStrategyManager.shared.update(selectedStrategy)
            }
            .store(in: &cancellables)
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
