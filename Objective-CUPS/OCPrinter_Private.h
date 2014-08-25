//
//  Printer_Private.h
//  Objective-CUPS
//
//  Created by Eldon on 5/3/14.
//  Copyright (c) 2014 Loyola University New Orleans. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface OCPrinter () <NSSecureCoding>
@property (nonatomic, readwrite) OSStatus status;
@property (copy, nonatomic) NSString *ppd_tempfile;
@property (weak, nonatomic, readwrite) NSArray *avaliableOptions;
@property (weak, nonatomic, readwrite) NSString *statusMessage;
@property (weak, nonatomic, readwrite) NSArray *jobs;
@end
