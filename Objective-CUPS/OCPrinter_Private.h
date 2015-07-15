//
//  Printer_Private.h
//  Objective-CUPS
//
//  Created by Eldon on 5/3/14.
//  Copyright (c) 2014 Loyola University New Orleans. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, OCPrinterHostType) {
    kOCUndefinedHostType,
    kOCPrinterHostTypeIPP = 1 << 0, // IPP
    kOCPrinterHostTypeIPPS = 1 << 1, // IPPS
    kOCPrinterHostTypeHTTP = 1 << 2, // HTTP
    kOCPrinterHostTypeHTTPS = 1 << 3, // HTTPS
    kOCPrinterHostTypeLPD = 1 << 4, // LPD
    kOCPrinterHostTypeSocket = 1 << 5, // Socket
    kOCPrinterHostTypeSMB = 1 << 6, // SMB
    kOCPrinterHostTypeDNSSD = 1 << 7, // DNS_SD
};

@interface OCPrinter () <NSSecureCoding>
@property (nonatomic, readwrite) OSStatus status;
@property (copy, nonatomic, readonly) NSString *ppd_tempfile;
@property (copy, nonatomic, readwrite) NSString *statusMessage;
@property (copy, nonatomic, readwrite) NSArray *jobs;
@property (nonatomic, readonly) OCPrinterHostType hostType;

@end
