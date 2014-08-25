//
//  OCManager.h
//  Objective-CUPS
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
@class OCPrinter, OCPrintJob;

/**
 *  Interface to the CUPS system 
 */
@interface OCManager : NSObject

+ (OCManager *)sharedManager;
/**
 Adds a Printer
 @param printer a populated Printer Object
 @note Required Keys for Printer Object: name, host, protocol, model.
 @note Optional Keys for Printer Object: description, location, options.
 @param error initialized and set if error occurs
 @return Returns `YES` if printer was successfully added, or `NO` on failure.
 
 */
- (BOOL)addPrinter:(OCPrinter *)printer;
- (BOOL)addPrinter:(OCPrinter *)printer error:(NSError **)error;

/**
 remove a Printer
 @param printer the name of the printer destination as registered with CUPS
 @param error initialized and set if error occurs
 @return `YES` if printer was successfully remvoed, `NO` on failure
 */
- (BOOL)removePrinter:(NSString *)printer;
- (BOOL)removePrinter:(NSString *)printer error:(NSError **)error;

#pragma mark - Options
/**
 Adds a single option to the specified printer
 @param option single option.
 @note  key and value conform to lpoption syntax ie "Opt_Key=Set_Value"
 @param printer the name of the printer destination as registered with CUPS
 @note must conform to lpoptions syntax
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)addOption2:(NSString *)option toPrinter:(NSString *)printer; // add single option conforming to lpoptions syntax
/**
 Adds an array of options to the specified printer
 @param options array of option
 @param printer the name of the printer destination as registered with CUPS
 @note must conform to lpoptions syntax
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)addOptions2:(NSArray *)options toPrinter:(NSString *)printer; // add list option conforming to lpoptions syntax

/**
 Adds a single option to the specified printer, parsing to PPD file
 @param option single option.
 @note  key and value conform to lpoption syntax ie "Opt_Key=Set_Value"
 @note this must be used on OS X as of 10.9.2 since GUI components don't pick up values in lpotions file
 @param printer the name of the printer destination as registered with CUPS
 @note must conform to lpoptions syntax
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)addOption:(NSArray *)opt toPrinter:(NSString *)printer;

/**
 Adds an array of options to the specified printer. Use with OS X
 @param options array of option
 @note  key and value conform to lpoption syntax ie "Opt_Key=Set_Value"
 @note this must be used on OS X as of 10.9.2 since GUI components don't pick up values in lpotions file
 @param printer the name of the printer destination as registered with CUPS
 @note must conform to lpoptions syntax
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)addOptions:(NSArray *)options toPrinter:(NSString *)printer; // add list option conforming to lpoptions syntax

#pragma mark - Status Modifier
/**
 Enable Printer
 @param printer the name of the printer destination as registered with CUPS
 @param error initialized and set if error occurs
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)enablePrinter:(NSString *)printer;
- (BOOL)enablePrinter:(NSString *)printer error:(NSError **)error;

/**
 Disable Printer
 @param printer the name of the printer destination as registered with CUPS
 @param error initialized and set if error occurs
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)disablePrinter:(NSString *)printer;
- (BOOL)disablePrinter:(NSString *)printer error:(NSError **)error;

#pragma mark - Printer Jobs
/**
 description
 @param File Path to the file to print
 @param printer the name of the printer destination as registered with CUPS
 @param error initialized and set if error occurs
 @return Returns `YES` on success, or `NO` on failure.
 */
- (OCPrintJob *)sendFile:(NSString *)file toPrinter:(NSString *)printer;
- (OCPrintJob *)sendFile:(NSString *)file toPrinter:(NSString *)printer error:(NSError **)error;

/**
 *  Send a file to a printer and monitor using a reply block
 *
 *  @param file    File Path to the file to print
 *  @param printer  printer the name of the printer destination as registered with CUPS
 *  @param error   error initialized and set if error occurs
 *  @param watch   block used to monitor the status of the Print job;
 */
- (void)sendFile:(NSString *)file
       toPrinter:(NSString *)printer
         failure:(void (^)(NSError *error))failure
           watch:(void (^)(NSString *status, NSInteger jobID))watch;

/**
 description
 @param URL to the file to print
 @note the url must be to a local file not a web address
 @param printer the name of the printer destination as registered with CUPS
 @param error initialized and set if error occurs
 @return Returns `YES` on success, or `NO` on failure.
 */
- (OCPrintJob *)sendFileAtURL:(NSURL *)file toPrinter:(NSString *)printer;
- (OCPrintJob *)sendFileAtURL:(NSURL *)file toPrinter:(NSString *)printer error:(NSError **)error;

/**
 description
 @param
 @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)cancelJobsOnPrinter:(NSString *)printer;
- (BOOL)cancelJobsOnPrinter:(NSString *)printer error:(NSError **)error;
#pragma mark - Class Methods
/**
 Gets a list with Populated Printer Objects of the currently installed printers
 @return NSSet of Printers Objects
 */
+ (NSSet *)installedPrinters;
/**
 Gets a list of the currently installed printers by name
 @return NSSet with the names of the installed printers
 */
+ (NSSet *)namesOfInstalledPrinters;
/**
 Gets a list of the options avaliable for particular printer model
 @return NSSet of installed printers
 */
+ (NSArray *)optionsForModel:(NSString *)model;

/**
 *  get an array of ppds for the given model
 *
 *  @param model model name
 *
 *  @return array with avaliable ppds for the particular model
 */
+ (NSArray *)ppdsForModel:(NSString *)model;

@end
