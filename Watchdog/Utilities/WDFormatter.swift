//
//  WDFormatter.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/5.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import AppKit

class RangedNumberFormatter: NumberFormatter {

    let range: ClosedRange<Int>

    init(range: ClosedRange<Int>) {
        self.range = range
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.count == 0 {
            return true
        }

        guard let number = Int(partialString) else {
            NSSound.beep()
            return false
        }

        let valid = range.contains(number)
        if !valid {
            NSSound.beep()
        }
        return valid
    }

}
