//
//  WDUtility.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

func machTime() -> TimeInterval {
    let time = mach_absolute_time();
    var timebase = mach_timebase_info_data_t();
    mach_timebase_info(&timebase);
    return TimeInterval(time) * TimeInterval(timebase.numer) / TimeInterval(timebase.denom) / TimeInterval(NSEC_PER_SEC);
}
