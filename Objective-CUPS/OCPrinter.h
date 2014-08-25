//
//  Printer.h
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

/**Class for Adding, Removing & Modifying CUPS Printers*/
@interface OCPrinter : NSObject
#pragma mark - Properties

/**CUPS compliant name for a printer destination*/
@property (copy, nonatomic) NSString *name;

/**FQDN or IP address to the CUPS Server or Printer */
@property (copy, nonatomic) NSString *host;

/** An approperiate protocol for the printer.
    @note Currently avaliabel protocols are: ipp, http, https, socket, lpd, dnssd
 */
@property (copy, nonatomic) NSString *protocol;

/**A human readable description of the printer */
@property (copy, nonatomic) NSString *description;

/**A human readable location of the printer */
@property (copy, nonatomic) NSString *location;

/** model name matching a result from lpinfo -m (end of each line)*/
@property (copy, nonatomic) NSString *model;

/**path to raw ppd file either .gz or .ppd */
@property (copy, nonatomic) NSString *ppd;

/** path where a PPD file can be download*/
@property (copy, nonatomic) NSString *ppd_url;

/** Array of options that use the lpoptions structure (e.g Option=Value).  
 A list of avaliable options can be obtained via lpoptions -p printer -l */
@property (copy, nonatomic) NSArray *options;

/** Array of options that can get applied to the printer 
based on the model*/
@property (weak, nonatomic, readonly) NSArray *avaliableOptions;

/**current numeric state of printer */
@property (nonatomic, readonly) OSStatus status;

/**current textual state of printer */
@property (weak, nonatomic, readonly) NSString *statusMessage;

/**currently printing jobs */
@property (weak, nonatomic, readonly) NSArray *jobs;

/**full uri for cups dest*/
@property (copy, nonatomic) NSString *url __deprecated;

/**full uri for cups dest*/
@property (copy, nonatomic) NSString *uri;

#pragma mark - Methods
/**
 initialize the Printer Object with a dictionary of matching keys
 @param dict Dictionary of keys.
 @note Required Keys: name, host, protocol, model.
 @note Optional Keys: description, location, options.
 @return self, initialized using dictionary.
 */
- (id)initWithDictionary:(NSDictionary *)dict;

@end
