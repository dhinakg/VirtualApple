#include <Foundation/Foundation.h>
#include <MacTypes.h>
#include <Virtualization/Virtualization.h>
// #include <objc/NSObject.h>
#include <objc/objc.h>
#include <objc/runtime.h>

#include <array>
#include <cstddef>

@interface _VZMacSerialNumber : NSObject <NSCopying>

@property(readonly, copy) NSString* string;

- (instancetype)initWithString:(NSString*)string;

@end

@implementation NSObject (KeyStuff)

- (NSArray*)allPropertyNames {
    unsigned count;
    objc_property_t* properties = class_copyPropertyList([self class], &count);

    NSMutableArray* rv = [NSMutableArray array];

    unsigned i;
    for (i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString* name = [NSString stringWithUTF8String:property_getName(property)];
        NSLog(@"Attributes for %@: %s", name, property_getAttributes(property));
        [rv addObject:name];
    }

    free(properties);

    return rv;
}

- (NSDictionary*)allProperties {
    NSMutableDictionary* rv = [NSMutableDictionary dictionary];
    for (NSString* name in [self allPropertyNames]) {
        rv[name] = [self valueForKey:name];
    }
    return rv;
}

@end

@interface FakeSerialNumber : NSObject <NSCopying> {
    struct AvpSerialNumber {
        std::array<uint8_t, 12> _serial_number;
    } _serialNumber;
}
@property(readonly, copy) NSString* string;
@end

@implementation FakeSerialNumber
- (instancetype)initWithString:(NSString*)string {
    if (!string || [string length] != 12) {
        return nil;
    }

    if ((self = [super init])) {
        const uint8_t* bytes = (const uint8_t*)[string UTF8String];
        memcpy(_serialNumber._serial_number.data(), bytes, 12);
    }
    return self;
}
- (NSString*)string {
    return [[NSString alloc] initWithBytes:_serialNumber._serial_number.data() length:12 encoding:NSUTF8StringEncoding];
}
- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[FakeSerialNumber class]]) {
        return NO;
    }

    FakeSerialNumber* other = (FakeSerialNumber*)object;

    return memcmp(_serialNumber._serial_number.data(), other->_serialNumber._serial_number.data(), 12) == 0;
}
- (nonnull id)copyWithZone:(nullable NSZone*)zone {
    return nil;
}
@end

@interface FakeSerialNumber2 : NSObject <NSCopying> {
    NSString* string;
}
@property(readonly, copy) NSString* string;
@end

@implementation FakeSerialNumber2
- (instancetype)initWithString:(NSString*)string {
    if (!string) {
        return nil;
    }

    if ((self = [super init])) {
        self->string = string;
    }
    return self;
}

- (NSString*)string {
    return string;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[FakeSerialNumber2 class]]) {
        return NO;
    }

    FakeSerialNumber2* other = (FakeSerialNumber2*)object;

    return [string isEqualToString:other->string];
}

- (nonnull id)copyWithZone:(nullable NSZone*)zone {
    FakeSerialNumber2* newNumber = [[[self class] allocWithZone:zone] init];
    newNumber->string = [string copyWithZone:zone];
    return newNumber;
}
@end

@interface _VZMacMachineIdentifier : NSObject {
}

+ (id)_machineIdentifierForVirtualMachineClone;
+ (id)_machineIdentifierForVirtualMachineCloneWithECID:(id)arg1 serialNumber:(SEL)arg2;
+ (id)_machineIdentifierForVirtualMachineCloneWithSerialNumber:(id)arg1;
+ (id)_machineIdentifierWithECID:(id)arg1 serialNumber:(SEL)arg2;
+ (id)_machineIdentifierWithSerialNumber:(id)arg1;
@end

NSString* patched__VZMacSerialNumber_string(_VZMacSerialNumber* self, SEL _cmd) {
    return @"CR4F0XQXF9AAAAAA";
}

NSString* exportable(VZMacMachineIdentifier* identifier) {
    return [[identifier dataRepresentation] base64EncodedStringWithOptions:0];
}

NSDictionary* readable(VZMacMachineIdentifier* identifier) {
    return [NSPropertyListSerialization propertyListWithData:[identifier dataRepresentation] options:0 format:0 error:nil];
}

int main(int argc, char** argv) {
    NSLog(@"Hello");
    VZMacMachineIdentifier* identifier = [[VZMacMachineIdentifier alloc] init];
    NSLog(@"ECID: %@", [identifier valueForKey:@"ECID"]);

    FakeSerialNumber* serial = [[FakeSerialNumber alloc] initWithString:@"CAAAAAAAAAAA"];
    if (!serial) {
        NSLog(@"Failed to create serial");
        return 1;
    }

    _VZMacSerialNumber *serial2 = [[_VZMacSerialNumber alloc] initWithString:@"BBBBBBBBBB"];
    if (!serial2) {
        NSLog(@"Failed to create serial2");
        return 1;
    }

    [serial2 setValue:[serial valueForKey:@"_serialNumber"] forKey:@"_serialNumber"];
    NSLog(@"Serial2: %@", [serial2 string]);

    Method m = class_getInstanceMethod([_VZMacSerialNumber class], @selector(string));
    method_setImplementation(m, (IMP)patched__VZMacSerialNumber_string);

    NSLog(@"Serial2: %@", [serial2 string]);


    NSLog(@"Serial: %@", [identifier valueForKey:@"serialNumber"]);
    [identifier setValue:serial forKey:@"_serialNumber"];
    NSLog(@"Serial: %@", [identifier valueForKey:@"_serialNumber"]);
    NSLog(@"Encoded: %@", [[identifier dataRepresentation] base64EncodedStringWithOptions:0]);
    NSLog(@"Decoded: %@", [NSPropertyListSerialization propertyListWithData:[identifier dataRepresentation] options:0 format:0 error:nil]);

    VZMacMachineIdentifier* reconstructed = [[VZMacMachineIdentifier alloc] initWithDataRepresentation:[identifier dataRepresentation]];
    NSLog(@"Reconstructed: %@", reconstructed);

    VZMacMachineIdentifier* fresh = [VZMacMachineIdentifier _machineIdentifierWithSerialNumber:serial];
    NSLog(@"Fresh: %@", fresh);
    NSLog(@"Encoded: %@", exportable(fresh));
    NSLog(@"Decoded: %@", readable(fresh));

    NSDictionary* raw = @{@"ECID": @2942017033696866274, @"SerialNumber": @"LR4F0XQXF9"};

    VZMacMachineIdentifier* test1 = [VZMacMachineIdentifier _machineIdentifierWithSerialNumber:serial2];
    VZMacMachineIdentifier* test2 = [VZMacMachineIdentifier _machineIdentifierWithECID:1 serialNumber:serial2];
    VZMacMachineIdentifier* test3 = [VZMacMachineIdentifier _machineIdentifierWithECID:1.9 serialNumber:nil];

    NSLog(@"Test1: %@", test1);
    NSLog(@"Test2: %@", test2);
    NSLog(@"Test3: %@", test3);

    NSLog(@"Test1 Decoded: %@", readable(test1));
    NSLog(@"Test2 Decoded: %@", readable(test2));
    NSLog(@"Test3 Decoded: %@", readable(test3));


    // VZMacMachineIdentifier* identifier2 = [[VZMacMachineIdentifier alloc] initWithDataRepresentation:[NSPropertyListSerialization
    // dataWithPropertyList:raw format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil]]; NSLog(@"Identifier 2: %@", identifier2);

    if (argc < 2) {
        NSLog(@"Usage: %s <path to ipsw>", argv[0]);
        return 1;
    }

    CFRunLoopRef rl = CFRunLoopGetCurrent();
    [VZMacOSRestoreImage loadFileURL:[NSURL fileURLWithPath:@(argv[1])] completionHandler:^(VZMacOSRestoreImage* image, NSError* err) {
        if (err) {
            NSLog(@"Error: %@", err);
            CFRunLoopStop(rl);
            return;
        }

        NSLog(@"Image: %@", image);
        NSLog(@"Build: %@", image.buildVersion);
        NSLog(@"OS Version: %ld.%ld.%ld", (long)image.operatingSystemVersion.majorVersion, (long)image.operatingSystemVersion.minorVersion,
              (long)image.operatingSystemVersion.patchVersion);

        VZMacOSConfigurationRequirements* requirements = image.mostFeaturefulSupportedConfiguration;
        NSLog(@"Config requirements: %@", requirements);

        NSLog(@"\tMinimum supported CPU count: %ld", (long)requirements.minimumSupportedCPUCount);
        NSLog(@"\tMinimum supported memory size: %llu", requirements.minimumSupportedMemorySize);

        VZMacHardwareModel* model = requirements.hardwareModel;
        NSLog(@"\tHardware model: %@", model);

        NSLog(@"\t\tModel as data: %@", [[model dataRepresentation] base64EncodedStringWithOptions:0]);

        NSLog(@"\t\tModel internal state: %@", [model allProperties]);

        CFRunLoopStop(rl);
    }];
    CFRunLoopRun();
}