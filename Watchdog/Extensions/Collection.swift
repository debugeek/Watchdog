//
//  Array.swift
//  Watchdog
//
//  Created by Xiao Jin on 2022/7/14.
//  Copyright © 2022 debugeek. All rights reserved.
//

extension BidirectionalCollection where Iterator.Element: Equatable {
    typealias Element = Self.Iterator.Element

    func next(of item: Element) -> Element? {
        if let itemIndex = self.firstIndex(of: item) {
            let lastItem = index(after: itemIndex) == endIndex
            if lastItem {
                return nil
            } else {
                return self[index(after: itemIndex)]
            }
        }
        return nil
    }

    func previous(of item: Element) -> Element? {
        if let itemIndex = self.firstIndex(of: item) {
            let firstItem = itemIndex == startIndex
            if firstItem {
                return nil
            } else {
                return self[index(before: itemIndex)]
            }
        }
        return nil
    }
    
}
