//
//  Swizzling.m
//  VirtualApple
//
//  Created by Dhinak G on 8/12/23.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


// @interface _VZMacSerialNumber : NSObject <NSCopying>

// @property(readonly, copy) NSString* string;

// - (instancetype)initWithString:(NSString*)string;

// @end


// NSString* patched__VZMacSerialNumber_string(_VZMacSerialNumber* self, SEL _cmd) {
//     NSLog(@"Asking for string");
//     return @"C02XQ0J0MD6H";
// }

// @interface OnLoad : NSObject
// @end


// @implementation OnLoad


// +(void)load {
//     NSLog(@"It has loaded");
//     Method m = class_getInstanceMethod([_VZMacSerialNumber class], @selector(string));
//     NSLog(@"Method is %p", m);
//     method_setImplementation(m, (IMP)patched__VZMacSerialNumber_string);
// }

// @end
