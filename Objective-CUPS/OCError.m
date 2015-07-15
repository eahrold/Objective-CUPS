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
    case kPrinterErrorInvalidURL:
        codeText = NSLocalizedStringFromTable(@"The URL to the printer is incorrect.",
                                              @"ObjecitveCUPS",
                                              @"Error when url is incorrect");
        break;
    case kPrinterErrorPPDNotFound:
        codeText = NSLocalizedStringFromTable(@"No PPD Avaliable, please download and install the drivers from the manufacturer.",
                                              @"ObjecitveCUPS",
                                              @"Error when url is incorrect");
        break;
    case kPrinterErrorInvalidProtocol:
        codeText = NSLocalizedStringFromTable(@"That url scheme is not supported at this time",
                                               @"ObjecitveCUPS",
                                               @"Error when url is incorrect");
        break;
    case kPrinterErrorCantWriteFile:
        codeText = NSLocalizedStringFromTable(@"Unable to write to PPD file",
                                              @"ObjecitveCUPS",
                                              @"Error when the the PPD file path is not access() W_OK");
        break;
    case kPrinterErrorCantOpenPPD:
        codeText = NSLocalizedStringFromTable(@"Unable to open PPD file",
                                              @"ObjecitveCUPS",
                                              @"Error when the ppd file cannot be opened do to permissions or existance");

        break;
    case kPrinterErrorIncompletePrinter:
        codeText = NSLocalizedStringFromTable(@"Some Required attributes for the printer were not supplied",
                                              @"ObjecitveCUPS",
                                              @"Missing or invalid parameters when adding a printer");

        break;
    case kPrinterErrorBadCharactersInName:
        codeText = NSLocalizedStringFromTable(@"The printer name must only be printable characters",
                                              @"ObjecitveCUPS",
                                              @"Error because the printer name is not valid due to invalid characters");

        break;
    case kPrinterErrorNameTooLong:
        codeText = NSLocalizedStringFromTable(@"The printer name is too long",
                                              @"ObjecitveCUPS",
                                              @"Error becuase the printer name is too long");

        break;
    case kPrinterErrorProblemCancelingJobs:
        codeText = NSLocalizedStringFromTable(@"There was a problem canceling some jobs",
                                              @"ObjecitveCUPS",
                                              @"Error when failed to cancel all jobs");

        break;
    case kPrintJobAlreaySubmitted:
        codeText = NSLocalizedStringFromTable(@"Print jobs can only be submitted once",
                                              @"ObjecitveCUPS",
                                              @"Error when submitting the same job multiple times.");

        break;
    case kPrintJobNoFileSubmitted:
        codeText = NSLocalizedStringFromTable(@"The print jobs was never submitted",
                                              @"ObjecitveCUPS",
                                              @"Error when a job was not submitted");

        break;
    default:
        codeText = NSLocalizedStringFromTable(@"There was a unknown problem.",
                                              @"ObjecitveCUPS",
                                              @"Generic error message");

        break;
    }
    return codeText;
}

@end
