//
//  IOHID.m
//  wdctl
//
//  Created by Xiao Jin on 2021/8/7.
//  Copyright © 2021 debugeek. All rights reserved.
//

#include "IOHID.h"

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <IOKit/hid/IOHIDKeys.h>

#define IOHIDEventFieldBase(type)   (type << 16)
#define kIOHIDEventTypeTemperature 15

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif


IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
int IOHIDEventSystemClientSetMatchingMultiple(IOHIDEventSystemClientRef client, CFArrayRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t , int32_t, int64_t);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

CFDictionaryRef IOHIDEventSystemClientCreateMatching(int page, int usage) {
    CFNumberRef nums[2];
    CFStringRef keys[2];
    
    keys[0] = CFStringCreateWithCString(0, kIOHIDPrimaryUsagePageKey, 0);
    keys[1] = CFStringCreateWithCString(0, kIOHIDPrimaryUsageKey, 0);
    nums[0] = CFNumberCreate(0, kCFNumberSInt32Type, &page);
    nums[1] = CFNumberCreate(0, kCFNumberSInt32Type, &usage);
    
    CFDictionaryRef dict = CFDictionaryCreate(0, (const void**)keys, (const void**)nums, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    return dict;
}

NSDictionary *getSensorValues(int page, int usage) {
    CFDictionaryRef sensor = IOHIDEventSystemClientCreateMatching(page, usage);
    
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, sensor);
    CFArrayRef services = IOHIDEventSystemClientCopyServices(system);
    
    long count = CFArrayGetCount(services);
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
        
        CFStringRef name = IOHIDServiceClientCopyProperty(service, CFSTR("Product"));
        if (!name) {
            name = CFSTR("noname");
        }
        
        double temperature = 0;
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(service, kIOHIDEventTypeTemperature, 0, 0);
        if (event) {
            temperature = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
            CFRelease(event);
        }
        
        results[CFBridgingRelease(name)] = @(temperature);
    }
    
    
    CFRelease(services);
    CFRelease(system);
    
    return results;
}
