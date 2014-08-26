//
//  Printer.m
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

#import "OCPrinter.h"
#import "OCPrinter_Private.h"
#import "OCPrintJob.h"
#import "OCError.h"
#import "OCManager.h"
#import <cups/cups.h>
#import <cups/ppd.h>
#import <zlib.h>
#import <syslog.h>

typedef NS_ENUM(NSInteger, ppdDownloadModes) {
    PPD_FROM_URL = 0,
    PPD_FROM_CUPS_SERVER = 1,
};

@implementation OCPrinter
// Since this overrides the standard NSObject description property, manually synthesize it
@synthesize description = _description;

#pragma mark - Initializers / Secure Coding
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        NSSet *whiteList = [NSSet setWithObjects:[NSDictionary class],
                                                 [NSString class],
                                                 [NSArray class],
                                                 nil];

        _name = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _host = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"host"];
        _location = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"location"];
        _description = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"description"];
        _ppd = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"ppd"];
        _ppd_url = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"ppd_url"];
        _model = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"model"];
        _protocol = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"protocol"];
        _url = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"url"];
        _uri = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"uri"];
        _host = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"host"];
        _options = [aDecoder decodeObjectOfClasses:whiteList forKey:@"options"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding { return YES; }

- (void)encodeWithCoder:(NSCoder *)aEncoder
{
    [aEncoder encodeObject:_name forKey:@"name"];
    [aEncoder encodeObject:_host forKey:@"host"];
    [aEncoder encodeObject:_location forKey:@"location"];
    [aEncoder encodeObject:_description forKey:@"description"];
    [aEncoder encodeObject:_ppd forKey:@"ppd"];
    [aEncoder encodeObject:_ppd_url forKey:@"ppd_url"];
    [aEncoder encodeObject:_model forKey:@"model"];
    [aEncoder encodeObject:_protocol forKey:@"protocol"];
    [aEncoder encodeObject:_url forKey:@"url"];
    [aEncoder encodeObject:_uri forKey:@"uri"];
    [aEncoder encodeObject:_host forKey:@"host"];
    [aEncoder encodeObject:_options forKey:@"options"];
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)dealloc
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.ppd_tempfile])
        [fm removeItemAtPath:self.ppd_tempfile error:nil];
}

#pragma mark - Accessors
- (NSString *)url
{
    return self.uri;
}

- (NSString *)uri
{
    if (_uri) {
        return _uri;
    }

    if (!_name || !_protocol || !_host) {
        NSLog(@"%@", [NSString stringWithFormat:@"Values Cannot be nil printer:%@ protocol:%@ host:%@", _name, _protocol, _host]);
        return nil;
    }

    // ipp and ipps for connecting to CUPS server
    if ([_protocol isEqualToString:@"ipp"] || [_protocol isEqualToString:@"ipps"]) {
        _uri = [NSString stringWithFormat:@"%@://%@/printers/%@", _protocol, _host, _name];
    }
    // http and https for connecting to CUPS server
    else if ([_protocol isEqualToString:@"http"] || [_protocol isEqualToString:@"https"]) {
        _uri = [NSString stringWithFormat:@"%@://%@:631/printers/%@", _protocol, _host, _name];
    }
    // socket for connecting to AppSocket
    else if ([_protocol isEqualToString:@"socket"]) {
        _uri = [NSString stringWithFormat:@"%@://%@:9100", _protocol, _host];
    } else if ([_protocol isEqualToString:@"lpd"]) {
        _uri = [NSString stringWithFormat:@"%@://%@", _protocol, _host];
    } else if ([_protocol isEqualToString:@"smb"]) {
        _uri = [NSString stringWithFormat:@"%@://%@/%@", _protocol, _host, _name];
    } else if ([_protocol isEqualToString:@"dnssd"]) {
        _uri = [NSString stringWithFormat:@"%@://%@._pdl-datastream._tcp.local./?bidi", _protocol, _host];
    } else {
        NSLog(@"Improper uri Format");
        return NO;
    }
    return [_uri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)host
{
    return [_host stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)ppd
{
    if (_ppd)
        return _ppd;
    else
        return [[OCManager ppdsForModel:_model] lastObject];
}

- (NSString *)ppd_tempfile
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:_name];
}

- (NSArray *)jobs
{
#ifdef _OBJECTIVE_CUPS_
    _jobs = [PrintJob jobsForPrinter:_name];
#endif
    return _jobs;
}

- (OSStatus)status
{
    cups_dest_t *dests,
        *dest;

    const char *value;
    int num_dests;

    num_dests = cupsGetDests(&dests);
    dest = cupsGetDest(_name.UTF8String, NULL, num_dests, dests);
    if (dest == NULL) {
        return 0;
    };

    if (dest->instance == NULL) {
        value = cupsGetOption("printer-state", dest->num_options, dest->options);
        _status = [[NSString stringWithUTF8String:value] intValue];
    }

    cupsFreeDests(num_dests, dests);
    return _status;
}

- (NSString *)statusMessage
{
    OSStatus status = self.status;
    switch (status) {
    case IPP_PRINTER_IDLE:
        _statusMessage = @"Idle";
        break;
    case IPP_PRINTER_PROCESSING:
        _statusMessage = @"Processing";
        break;
    case IPP_PRINTER_STOPPED:
        _statusMessage = @"Stopped";
        break;
    default:
        _statusMessage = @"unknown";
        break;
    }
    return _statusMessage;
}

- (NSArray *)avaliableOptions
{
    NSArray *opts = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *file = [NSString stringWithUTF8String:cupsGetPPD(_name.UTF8String)];
#pragma clang diagnostic pop
    if (file) {
        opts = [self optionsForPPD:file];
        unlink(file.UTF8String);
    }

    return opts;
}

#pragma mark - Private

- (BOOL)configurePPD:(NSError *__autoreleasing *)error
{
    NSString *path;

    // Check if we can find a match locally...
    NSString *localPPD = self.ppd;
    if (localPPD) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:localPPD]) {
            // If the file exists remove it so we can get a new one.
            if ([fm fileExistsAtPath:self.ppd_tempfile])
                [fm removeItemAtPath:self.ppd_tempfile error:nil];

            if ([fm copyItemAtPath:localPPD toPath:self.ppd_tempfile error:nil]) {
                return YES;
            }
        }
    }

    // if not local, try and get if from the printer-installer-server
    if (_ppd_url) {
        path = [_ppd_url stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        if ([self downloadPPD:[NSURL URLWithString:path] mode:PPD_FROM_URL]) {
            return YES;
        }
    }

    // otherwise, if it's getting shared via ipp, try to grab it from the CUPS server
    if ([_protocol isEqualToString:@"ipp"]) {
        path = [NSString stringWithFormat:@"http://%@:631/printers/%@.ppd", _host, _name];
        if ([self downloadPPD:[NSURL URLWithString:path] mode:PPD_FROM_CUPS_SERVER]) {
            return YES;
        }
    }
    // if we still don't have it error out
    return [OCError errorWithCode:kPrinterErrorPPDNotFound error:error];
}

- (BOOL)downloadPPD:(NSURL *)URL mode:(ppdDownloadModes)mode
{
    if (!URL) {
        return NO;
    }

    NSError *error = nil;
    NSHTTPURLResponse *response = nil;

    // Create the request.
    NSMutableURLRequest *ppdRequest = [NSMutableURLRequest requestWithURL:URL];

    // set as GET request
    ppdRequest.HTTPMethod = @"GET";
    ppdRequest.timeoutInterval = 3;

    // set header fields
    [ppdRequest setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    // Create url connection and fire request
    NSData *data = [NSURLConnection sendSynchronousRequest:ppdRequest
                                         returningResponse:&response
                                                     error:&error];

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([response statusCode] >= 400 || !data) {
        [fm removeItemAtPath:self.ppd_tempfile error:nil];
        return NO;
    } else {
        NSString *downloadedPPD = [self.ppd_tempfile stringByAppendingString:@".gz"];
        if ([fm createFileAtPath:downloadedPPD contents:data attributes:nil]) {
            if (mode == PPD_FROM_CUPS_SERVER) {
                return [fm moveItemAtPath:downloadedPPD toPath:self.ppd_tempfile error:&error];
            } else {
                return [self unzipPPD:downloadedPPD to:self.ppd_tempfile error:&error];
            }
        }
    }
    return NO;
}

- (BOOL)unzipPPD:(NSString *)inPath to:(NSString *)outPath error:(NSError *__autoreleasing *)error
{
    int CHUNK = 0x1000;
    unsigned char buffer[CHUNK];
    gzFile file = gzopen([inPath UTF8String], "r");
    NSMutableData *bufferData = [[NSMutableData alloc] init];

    while (1) {
        int err;
        int bytes_read;
        bytes_read = gzread(file, buffer, CHUNK - 1);
        buffer[bytes_read] = '\0';
        [bufferData appendBytes:buffer length:bytes_read];

        if (bytes_read < CHUNK - 1) {
            if (gzeof(file)) {
                break;
            } else {
                const char *error_string;
                error_string = gzerror(file, &err);
                if (err) {
                    [OCError charError:error_string error:error];
                    return NO;
                }
            }
        }
    }
    gzclose(file);
    return [bufferData writeToFile:outPath atomically:YES];
}

- (BOOL)nameIsValid:(NSError *__autoreleasing *)error
{
    const char *name = _name.UTF8String;
    const char *ptr;

    for (ptr = name; *ptr; ptr++) {
        if (*ptr == '@') {
            break;
        } else if ((*ptr >= 0 && *ptr <= ' ') || *ptr == 127 || *ptr == '/' || *ptr == '#') {
            [OCError errorWithCode:kPrinterErrorBadCharactersInName error:error];
            return NO;
        }
    }

    /*
     * All the characters are good; validate the length, too...
     */
    if ((ptr - name) > 127) {
        [OCError errorWithCode:kPrinterErrorNameTooLong error:error];
        return NO;
    }
    return YES;
}

- (NSArray *)optionsForPPD:(NSString *)file
{
    NSMutableArray *array = [NSMutableArray new];

    int i, j; /* Looping var */
    ppd_file_t *ppd; /* PPD data */
    ppd_group_t *group; /* Current group */
    ppd_option_t *option; /* Current option */
    ppd_choice_t *choice; /* Current choice */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ((ppd = ppdOpenFile(file.UTF8String)) == NULL) {
        return nil;
    }

    ppdMarkDefaults(ppd);

    for (i = ppd->num_groups, group = ppd->groups; i > 0; i--, group++) {
        for (j = group->num_options, option = group->options; j > 0; j--, option++) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            NSMutableArray *choices = [NSMutableArray new];

            if (!strcasecmp(option->keyword, "PageRegion"))
                continue;

            for (j = option->num_choices, choice = option->choices; j > 0; j--, choice++) {
                [choices addObject:[NSString stringWithUTF8String:choice->choice]];
            }
            [dict setObject:[NSString stringWithUTF8String:option->keyword]
                     forKey:@"option"];
            [dict setObject:[NSString stringWithUTF8String:option->text] forKey:@"description"];
            [dict setObject:choices forKey:@"choices"];
            [array addObject:dict];
        }
    }
    ppdClose(ppd);
#pragma clang diagnostic pop
    return array;
}

@end
