//
//  main.swift
//  wdctl
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import ArgumentParser

struct wdctl: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [metrics.self])
}

wdctl.main()
