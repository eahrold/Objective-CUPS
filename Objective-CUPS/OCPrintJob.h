//
//  PrinterJob.h
//  ObjectiveCups
//
//  Copyright (c) 2014 Eldon Ahrold ( https://github.com/eahrold/Objective-CUPS )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//

#import <Foundation/Foundation.h>
@class OCPrintJob;

@protocol PrintJobMonitor <NSObject>
- (void)didRecieveStatusUpdate:(NSString *)msg job:(OCPrintJob *)job;
@end

/**Class for Monitoring Print Jobs*/
@interface OCPrintJob : NSObject

@property (weak) id<PrintJobMonitor> jobMonitor;

/**Name of the submitted print job*/
@property (copy) NSString *name;

/**Printer dest of the submitted print job*/
@property (copy) NSString *dest;

/**User who submitted the print job*/
@property (copy, nonatomic, readonly) NSString *user;

/**Job ID number*/
@property (nonatomic, readonly) NSInteger jid;

/**Size of the print job in Bytes*/
@property (nonatomic, readonly) NSInteger size;

/**Status of the print job*/
@property (readonly, nonatomic) OSStatus status;

/**Date the print Job was submitted*/
@property (nonatomic, readonly) NSInteger submitionDate;

/**Descriptive Status of the print job*/
@property (copy, nonatomic, readonly) NSString *statusDescription;

- (void)addFile:(NSString *)file;
- (void)addFiles:(NSArray *)files;

- (BOOL)submit;
- (BOOL)submit:(NSError **)error;

- (BOOL)hold;
- (BOOL)hold:(NSError **)error;

- (BOOL)start;
- (BOOL)start:(NSError **)error;

- (BOOL)cancel;
- (BOOL)cancel:(NSError **)error;

+ (NSArray *)jobsForPrinter:(NSString *)printer;
+ (NSArray *)jobsForPrinter:(NSString *)printer includeCompleted:(BOOL)include;

+ (NSArray *)jobsForAllPrinters;
+ (NSArray *)jobsForAllPrinterIncludingCompleted:(BOOL)includeCompleted;

+ (void)cancelAllJobs;
+ (BOOL)cancelJobWithID:(NSInteger)jid;
+ (BOOL)cancelJobWithID:(NSInteger)jid error:(NSError **)error;

+ (BOOL)cancelJobNamed:(NSString *)name;
+ (BOOL)cancelJobNamed:(NSString *)name error:(NSError **)error;

@end
