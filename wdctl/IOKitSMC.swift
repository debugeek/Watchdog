//
//  IOKitSMC.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/8/4.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import IOKit

enum SMCSelector: UInt8 {
    case kSMCUserClientOpen  = 0
    case kSMCUserClientClose = 1
    case kSMCHandleYPCEvent  = 2
    case kSMCReadKey         = 5
    case kSMCWriteKey        = 6
    case kSMCGetKeyCount     = 7
    case kSMCGetKeyFromIndex = 8
    case kSMCGetKeyInfo      = 9
}

struct SMCVersion {
    var major: CUnsignedChar = 0
    var minor: CUnsignedChar = 0
    var build: CUnsignedChar = 0
    var reserved: CUnsignedChar = 0
    var release: CUnsignedShort = 0
}

struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

struct SMCKeyInfoData {
    var dataSize: IOByteCount = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

typealias SMCBytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

struct SMCParamStruct {
    var key: UInt32 = 0
    var vers = SMCVersion()
    var pLimitData = SMCPLimitData()
    var keyInfo = SMCKeyInfoData()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: SMCBytes = (0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0)
}

struct SMCResult {
    let key: UInt32
    let dataType: UInt32
    let bytes: SMCBytes
}

extension SMCResult {

    var u8: UInt8 {
        return bytes.0
    }
    
    var u16: UInt16 {
        return UInt16(bytes.0) << 8 | UInt16(bytes.1)
    }
    
    var u32: UInt32 {
        return UInt32(bytes.0) << 24 | UInt32(bytes.1) << 16 | UInt32(bytes.2) << 8 | UInt32(bytes.3)
    }
    
    var i8: Int8 {
        return Int8(bytes.0)
    }
    
    var i16: Int16 {
        return Int16(bytes.0) << 8 | Int16(bytes.1)
    }
    
    var i32: Int32 {
        return Int32(bytes.0) << 24 | Int32(bytes.1) << 16 | Int32(bytes.2) << 8 | Int32(bytes.3)
    }
    
}

// https://opensource.apple.com/source/IOKitUser/IOKitUser-647.6/pwr_mgt.subproj/IOPMLibPrivate.c
enum SMCValueType: String {
    case FLT    = "flt "
    case FP1F   = "fp1f"
    case FP4C   = "fp4c"
    case FP5B   = "fp5b"
    case FP6A   = "fp6a"
    case FP79   = "fp79"
    case FP88   = "fp88"
    case FPA6   = "fpa6"
    case FPC4   = "fpc4"
    case FPE2   = "fpe2"
    case SP1E   = "sp1e"
    case SP3C   = "sp3c"
    case SP4B   = "sp4b"
    case SP5A   = "sp5a"
    case SP69   = "sp69"
    case SP78   = "sp78"
    case SP87   = "sp87"
    case SP96   = "sp96"
    case SPB4   = "spb4"
    case SPF0   = "spf0"
    case UINT8  = "ui8 "
    case UINT16 = "ui16"
    case UINT32 = "ui32"
    case SI8    = "si8 "
    case SI16   = "si16"
    case PWM    = "{pwm"
}

extension UInt32 {
    
    var SMCString: String? {
        guard let c1 = UnicodeScalar(self >> 24 & 0xff),
              let c2 = UnicodeScalar(self >> 16 & 0xff),
              let c3 = UnicodeScalar(self >> 8  & 0xff),
              let c4 = UnicodeScalar(self & 0xff) else {
            return nil
        }
        return String(describing: c1) + String(describing: c2) + String(describing: c3) + String(describing: c4)
    }
    
}

extension String {
    
    var SMCKey: UInt32? {
        guard count == 4 else {
            return nil
        }
        return utf8.reduce(0) { sumOfBits, character in
            return sumOfBits << 8 | UInt32(character)
        }
    }
    
}

class IOKitSMC {
    
    static let shared = IOKitSMC()
    
    var conn: io_connect_t = 0
    
    @discardableResult
    func open() -> Bool {
        var iterator: io_iterator_t = 0
        var result = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("AppleSMC"), &iterator)
        if result != kIOReturnSuccess {
            return false
        }
        
        let device = IOIteratorNext(iterator)
        IOObjectRelease(iterator)
        
        if device == 0 {
            return false
        }

        result = IOServiceOpen(device, mach_task_self_, 0, &conn)
        IOObjectRelease(device)
        
        return result == kIOReturnSuccess
    }
    
    @discardableResult
    func close() -> Bool {
        return IOServiceClose(conn) == kIOReturnSuccess
    }
    
    @discardableResult
    func call(input: inout SMCParamStruct, output: inout SMCParamStruct) -> Bool {
        let inputSize = MemoryLayout<SMCParamStruct>.stride
        var outputSize = MemoryLayout<SMCParamStruct>.stride
        let rv = IOConnectCallStructMethod(conn, UInt32(SMCSelector.kSMCHandleYPCEvent.rawValue), &input, inputSize, &output, &outputSize)
        return rv == kIOReturnSuccess
    }
    
    func getKeyInfo(key: UInt32) -> SMCKeyInfoData? {
        var input = SMCParamStruct()
        input.key = key
        input.data8 = SMCSelector.kSMCGetKeyInfo.rawValue
        
        var output = SMCParamStruct()
        if !call(input: &input, output: &output) {
            return nil
        }
        
        return output.keyInfo
    }
    
    func getResult(name: String) -> SMCResult? {
        guard let key = name.SMCKey,
              let keyInfo = getKeyInfo(key: key) else {
            return nil
        }
        
        var input = SMCParamStruct()
        input.key = key
        input.keyInfo = keyInfo
        input.data8 = SMCSelector.kSMCReadKey.rawValue
        
        var output = SMCParamStruct()
        if !call(input: &input, output: &output) {
            return nil
        }
        
        return SMCResult(key: key, dataType: keyInfo.dataType, bytes: output.bytes)
    }
    
    func getValue(name: String) -> Double? {
        guard let result = getResult(name: name) else {
            return nil
        }
        
        guard let dataType = result.dataType.SMCString,
              let valueType = SMCValueType(rawValue: dataType) else {
            return nil
        }
        
        switch valueType {
        case .FLT:
            var dst = [UInt8](repeating: 0, count: 32)
            var src = result.bytes
            memcpy(&dst, &src, 32)
            return Double(dst.withUnsafeBytes {
                return $0.load(fromByteOffset: 0, as: Float.self)
            })
        case .FP1F: return Double(result.u16)/32768.0
        case .FP4C: return Double(result.u16)/4096.0
        case .FP5B: return Double(result.u16)/2048.0
        case .FP6A: return Double(result.u16)/1024.0
        case .FP79: return Double(result.u16)/512.0
        case .FP88: return Double(result.u16)/256.0
        case .FPA6: return Double(result.u16)/64.0
        case .FPC4: return Double(result.u16)/16.0
        case .FPE2: return Double(result.u16)/4.0
        case .SP1E: return Double(result.i16)/16384.0
        case .SP3C: return Double(result.i16)/4096.0
        case .SP4B: return Double(result.i16)/2048.0
        case .SP5A: return Double(result.i16)/1024.0
        case .SP69: return Double(result.i16)/512.0
        case .SP78: return Double(result.i16)/256.0
        case .SP87: return Double(result.i16)/128.0
        case .SP96: return Double(result.i16)/64.0
        case .SPB4: return Double(result.i16)/16.0
        case .SPF0: return Double(result.i16)
        case .UINT8: return Double(result.u8)
        case .UINT16: return Double(result.u16)
        case .UINT32: return Double(result.u32)
        case .SI8: return Double(result.i8)
        case .SI16: return Double(result.i16)
        // case .PWM:
        default: return nil
        }
    }
    
}

extension IOKitSMC {
    
    func getAllKeys() -> [String]? {
        guard let count = getValue(name: "#KEY") else {
            return nil
        }
        
        var keys = [String]()
        for i in 0..<UInt32(count) {
            var input = SMCParamStruct()
            input.data8 = SMCSelector.kSMCGetKeyFromIndex.rawValue
            input.data32 = i
            
            var output = SMCParamStruct()
            if !call(input: &input, output: &output) {
                continue
            }
            
            if let key = output.key.SMCString {
                keys.append(key)
            }
        }
        
        return keys
    }
    
}

extension IOKitSMC {
    
    func getTemperatureValues() -> [String: Double]? {
        if !open() {
            return nil
        }
        
        defer { close() }
        
        guard let keys = getAllKeys()?.filter({ temperatureKeys.contains($0) }) else {
            return nil
        }
        
        return keys.reduce([String: Double]()) { (values, key) -> [String: Double] in
            var values = values
            if let value = getValue(name: key) {
                values[key] = value
            }
            return values
        }
    }
    
    var temperatureKeys: [String] {
        return ["TCXC", "TCXc", "TC0P", "TC0H", "TC0D", "TC0E", "TC0F", "TC1C", "TC2C", "TC3C", "TC4C", "TC5C", "TC6C", "TC7C", "TC8C", "TCAH",
                "TCAD", "TC1P", "TC1H", "TC1D", "TC1E", "TC1F", "TCBH", "TCBD", "TCSC", "TCSc", "TCSA", "TCGC", "TCGc", "TG0P", "TG0D", "TG1D",
                "TG0H", "TG1H", "Ts0S", "TM0P", "TM1P", "TM8P", "TM9P", "TM0S", "TM1S", "TM8S", "TM9S", "TN0D", "TN0P", "TN1P", "TN0C", "TN0H",
                "TP0D", "TPCD", "TP0P", "TA0P", "TA1P", "Th0H", "Th1H", "Th2H", "Tm0P", "Tp0P", "Ts0P", "Tb0P", "TL0P", "TW0P", "TH0P", "TH1P",
                "TH2P", "TH3P", "TO0P", "Tp0P", "Tp0C", "TB0T", "TB1T", "TB2T", "TB3T", "Tp1P", "Tp1C", "Tp2P", "Tp3P", "Tp4P", "Tp5P", "TS0C",
                "TA0S", "TA1S", "TA2S", "TA3S"]
    }
    
}
