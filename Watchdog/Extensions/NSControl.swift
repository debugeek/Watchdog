//
//  NSControl.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/5.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa
import Combine

final class NSControlSubscription<S: Subscriber, T: NSControl>: Subscription where S.Input == T {
    private var subscriber: S?
    private let control: T

    init(subscriber: S, control: T) {
        self.subscriber = subscriber
        self.control = control
        
        control.target = self
        control.action = #selector(invoke)
    }

    func request(_ demand: Subscribers.Demand) {
        
    }

    func cancel() {
        subscriber = nil
    }

    @objc private func invoke() {
        _ = subscriber?.receive(control)
    }
}

struct NSControlPublisher<T: NSControl>: Publisher {
    typealias Output = T
    typealias Failure = Never

    let control: T

    init(control: T) {
        self.control = control
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Never, S.Input == T {
        let subscription = NSControlSubscription(subscriber: subscriber, control: control)
        subscriber.receive(subscription: subscription)
    }
}

protocol CombineCompatible { }
extension NSControl: CombineCompatible { }
extension CombineCompatible where Self: NSControl {
    
    var clickPublisher: NSControlPublisher<NSControl> {
        return NSControlPublisher(control: self)
    }
    
    var textDidChangePublisher: AnyPublisher<String, Never> {
        return NotificationCenter.default
            .publisher(for: NSControl.textDidChangeNotification, object: self)
            .subscribe(on: DispatchQueue.main)
            .map { _ in self.stringValue }
            .eraseToAnyPublisher()
    }
    
    var textDidEndEditingPublisher: AnyPublisher<String, Never> {
        return NotificationCenter.default
            .publisher(for: NSControl.textDidEndEditingNotification, object: self)
            .subscribe(on: DispatchQueue.main)
            .map { _ in self.stringValue }
            .eraseToAnyPublisher()
    }
    
}

extension CombineCompatible where Self: NSPopUpButton {

    var indexOfSelectedItemPublisher: AnyPublisher<Int, Never> {
        return NotificationCenter.default
            .publisher(for: NSMenu.didSendActionNotification, object: menu)
            .subscribe(on: DispatchQueue.main)
            .map { _ in
                self.indexOfSelectedItem
            }
            .eraseToAnyPublisher()
    }
    
    var selectedItemPublisher: AnyPublisher<NSMenuItem?, Never> {
        return NotificationCenter.default
            .publisher(for: NSMenu.didSendActionNotification, object: menu)
            .subscribe(on: DispatchQueue.main)
            .map { _ in self.selectedItem }
            .eraseToAnyPublisher()
    }
    
}

extension CombineCompatible where Self: NSSegmentedControl {

    var selectedSegmentPublisher: AnyPublisher<Int, Never> {
        return clickPublisher
            .subscribe(on: DispatchQueue.main)
            .map { _ in self.selectedSegment }
            .eraseToAnyPublisher()
    }
    
}

extension CombineCompatible where Self: NSSwitch {
    
    var statePublisher: AnyPublisher<NSSwitch.StateValue, Never> {
        return clickPublisher
            .subscribe(on: DispatchQueue.main)
            .map { _ in self.state }
            .eraseToAnyPublisher()
    }
    
}


