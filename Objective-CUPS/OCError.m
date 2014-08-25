//
//  PrinterError.m
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

#import "OCError.h"
#import <cups/cups.h>
//  The Domain to user with error codes and Alert Panel
NSString *const PrinterErrorDomain = @"com.eeaapps.objective-CUPS";

@implementation OCError

+ (BOOL)errorWithCode:(int)code error:(NSError *__autoreleasing *)error
{
    NSString *message = [OCError errorTextForCode:code];
    [self errorWithCode:code message:message error:error];
    return NO;
}

+ (BOOL)cupsError:(NSError *__autoreleasing *)error
{
    NSString *message = [NSString stringWithUTF8String:cupsLastErrorString()];
    [self errorWithCode:cupsLastError() message:message error:error];
    return NO;
}

+ (BOOL)charError:(const char *)message error:(NSError *__autoreleasing *)error
{
    NSString *msg = [NSString stringWithUTF8String:message];
    [self errorWithCode:1 message:msg error:error];
    return NO;
}

+ (BOOL)errorWithCode:(NSInteger)code message:(NSString *)message error:(NSError *__autoreleasing *)error
{
    if (error)
        *error = [self errorWithCode:code message:message];
    else
        NSLog(@"%@", message);
    return NO;
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:PrinterErrorDomain
                                         code:code
                                     userInfo:@{ NSLocalizedDescriptionKey : message }];
    return error;
}

+ (NSString *)errorTextForCode:(int)code
{
    NSString *codeText = @"";
    switch (code) {
    case kPrinterErrorInvalidURL
        :
        codeText = @"The URL to the printer is incorrect.  Contact the System Admin";
        break;
    case kPrinterErrorPPDNotFound:
        codeText = @"No PPD Avaliable, please download and install the drivers from the manufacturer.";
        break;
    case kPrinterErrorInvalidProtocol:
        codeText = @"That url scheme is not supported at this time";
        break;
    case kPrinterErrorCantWriteFile:
        codeText = @"Unable to write to PPD file";
        break;
    case kPrinterErrorCantOpenPPD:
        codeText = @"Unable to open PPD file";
        break;
    case kPrinterErrorIncompletePrinter:
        codeText = @"Some Required attributes for the printer were not supplied";
        break;
    case kPrinterErrorBadCharactersInName:
        codeText = @"The printer name must only be printable characters";
        break;
    case kPrinterErrorNameTooLong:
        codeText = @"the printer name is too long";
        break;
    case kPrinterErrorProblemCancelingJobs:
        codeText = @"there was a problem canceling some jobs";
        break;
    case kPrintJobAlreaySubmitted:
        codeText = @"Print Jobs can only be submitted once";
        break;
    case kPrintJobNoFileSubmitted:
        codeText = @"Print Jobs can only be submitted once";
        break;
    default:
        codeText = @"There was a unknown problem, sorry!";
        break;
    }
    return codeText;
}

@end
