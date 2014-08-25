//
//  CUPSManager.m
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

#import "OCManager.h"
#import "OCPrinter.h"
#import "OCPrinter_Private.h"
#import "OCPrintJob.h"
#import "OCError.h"
#import "OCPrinter_Validator.h"
#import "OCPrinterUtility.h"
#import <cups/cups.h>
#import <cups/ppd.h>
#import <zlib.h>
#import <syslog.h>

@interface OCManager () <PrintJobMonitor>
@property (weak, nonatomic, readwrite) void (^jobStatus)(NSString *status, NSInteger jobID);
@end

@implementation OCManager {
}

- (void)dealloc
{
    NSLog(@"deallocated: %@", self);
}

- (void)didRecieveStatusUpdate:(NSString *)msg job:(OCPrintJob *)job
{
    if (_jobStatus) {
        _jobStatus(msg, job.jid);
    }
}

+ (OCManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static OCManager *shared;
    dispatch_once(&onceToken, ^{
        shared = [OCManager new];
    });
    return shared;
}

#pragma mark - Add Printer
- (BOOL)addPrinter:(OCPrinter *)printer
{
    return [self addPrinter:printer error:nil];
}

- (BOOL)addPrinter:(OCPrinter *)printer error:(NSError *__autoreleasing *)error
{
    if (![printer nameIsValid:error])
        return NO;

    if (![printer configurePPD:error])
        return NO;

    ipp_t *request;
    cups_option_t *options = NULL;

    int num_options = 0;

    const char *finalppd;

    char uri[HTTP_MAX_URI];

    request = ippNewRequest(CUPS_ADD_MODIFY_PRINTER);

    if (printer.location.UTF8String) {
        num_options = cupsAddOption("printer-location", printer.location.UTF8String, num_options, &options);
    }

    if (printer.description.UTF8String) {
        num_options = cupsAddOption("printer-info", printer.description.UTF8String, num_options, &options);
    }

    if (printer.options) {
        for (NSString *opt in printer.options) {
            num_options = cupsParseOptions([opt UTF8String], num_options, &options);
        }
    }

    num_options = cupsAddOption("device-uri", printer.uri.UTF8String,
                                num_options, &options);

    httpAssembleURIf(HTTP_URI_CODING_ALL, uri, sizeof(uri), "ipp", NULL,
                     "localhost", 0, "/printers/%s", printer.name.UTF8String);

    ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "printer-uri", NULL, uri);
    ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", NULL, cupsUser());

    cupsEncodeOptions2(request, num_options, options, IPP_TAG_OPERATION);
    cupsEncodeOptions2(request, num_options, options, IPP_TAG_PRINTER);

    if ((finalppd = writeOptionsToPPD(options, num_options, printer.ppd_tempfile.UTF8String, error)) == NULL) {
        return NO;
    }

    ippAddInteger(request, IPP_TAG_PRINTER, IPP_TAG_ENUM, "printer-state", IPP_PRINTER_IDLE);
    ippAddBoolean(request, IPP_TAG_PRINTER, "printer-is-accepting-jobs", 1);

    ippDelete(cupsDoFileRequest(CUPS_HTTP_DEFAULT, request, "/admin/", finalppd));
    unlink(finalppd);

    if (cupsLastError() > IPP_OK_CONFLICT) {
        return [OCError cupsError:error];
    }
    return YES;
}

#pragma mark - Add Options
- (BOOL)addOption:(NSArray *)opt toPrinter:(NSString *)printer
{
    return [self addOptions:@[ opt ] toPrinter:printer];
}

- (BOOL)addOptions:(NSArray *)opts toPrinter:(NSString *)printer
{
    NSError *error;
    ipp_t *request;
    char uri[HTTP_MAX_URI]; /* URI for printer/class */

    const char *ppdfile,
        *finalppd;

    BOOL rc;
    int num_options;
    cups_option_t *options;

    num_options = 0;
    options = NULL;
    request = ippNewRequest(CUPS_ADD_MODIFY_PRINTER);

    {
        for (NSString *opt in opts) {
            num_options = cupsParseOptions([opt UTF8String], num_options, &options);
        }
    }

    cupsEncodeOptions2(request, num_options, options, IPP_TAG_PRINTER);
    cupsEncodeOptions2(request, num_options, options, IPP_TAG_OPERATION);

    rc = YES;
    httpAssembleURIf(HTTP_URI_CODING_ALL, uri, sizeof(uri), "ipp", NULL,
                     "localhost", 0, "/printers/%s", printer.UTF8String);

    ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "printer-uri", NULL, uri);
    ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_NAME, "requesting-user-name", NULL, cupsUser());

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ppdfile = cupsGetPPD(printer.UTF8String);
#pragma clang diagnostic pop

    if ((finalppd = writeOptionsToPPD(options, num_options, ppdfile, &error)) == NULL) {
        return NO;
    }

    ippDelete(cupsDoFileRequest(CUPS_HTTP_DEFAULT, request, "/admin/", finalppd));

    if (ppdfile != finalppd)
        unlink(ppdfile);

    unlink(finalppd);

    if (cupsLastError() > IPP_OK_CONFLICT) {
        NSLog(@"%s", cupsLastErrorString());
        rc = NO;
    }
    return rc;
}

- (BOOL)addOption2:(NSString *)opt toPrinter:(NSString *)printer
{
    return [self addOptions:@[ opt ] toPrinter:printer];
}

- (BOOL)addOptions2:(NSArray *)opts toPrinter:(NSString *)printer
{
    cups_option_t *options = NULL;

    int num_options = 0,
        num_dests = 0;

    cups_dest_t *dest = NULL,
                *dests = NULL;

    char *instance;

    if ((instance = strrchr(printer.UTF8String, '/')) != NULL)
        *instance++ = '\0';

    if (num_dests == 0)
        num_dests = cupsGetDests(&dests);

    dest = cupsGetDest(printer.UTF8String, instance, num_dests, dests);
    if (dest == NULL) {
        num_dests = cupsAddDest(printer.UTF8String, instance, num_dests, &dests);
        dest = cupsGetDest(printer.UTF8String, instance, num_dests, dests);

        if (dest == NULL) {
            NSLog(@"unable to locate printer %@", printer);
            cupsFreeDests(num_dests, dests);
            return NO;
        }
    }

    for (int j = 0; j < dest->num_options; j++)
        if (cupsGetOption(dest->options[j].name, num_options, options) == NULL)
            num_options = cupsAddOption(dest->options[j].name,
                                        dest->options[j].value,
                                        num_options, &options);

    if (opts.count) {
        for (NSString *opt in opts) {
            num_options = cupsParseOptions(opt.UTF8String, num_options, &options);
        }
    }

    cupsFreeOptions(dest->num_options, dest->options);

    dest->num_options = num_options;
    dest->options = options;

    cupsSetDests(num_dests, dests);
    cupsFreeDests(num_dests, dests);

    return YES;
}

#pragma mark - Remove Printer
- (BOOL)removePrinter:(NSString *)printer
{
    return [self removePrinter:printer error:nil];
}

- (BOOL)removePrinter:(NSString *)printer error:(NSError *__autoreleasing *)error
{
    /* convert get these out of NSString */
    ipp_t *request;
    char uri[HTTP_MAX_URI];

    request = ippNewRequest(CUPS_DELETE_PRINTER);

    httpAssembleURIf(HTTP_URI_CODING_ALL, uri, sizeof(uri), "ipp", NULL,
                     "localhost", 0, "/printers/%s", printer.UTF8String);

    ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI,
                 "printer-uri", NULL, uri);

    ippDelete(cupsDoRequest(CUPS_HTTP_DEFAULT, request, "/admin/"));

    if (cupsLastError() > IPP_OK_CONFLICT) {
        return [OCError cupsError:error];
    }

    return YES;
}

#pragma mark - Jobs
- (BOOL)cancelJobsOnPrinter:(NSString *)printer
{
    return [self cancelJobsOnPrinter:printer error:nil];
}

- (BOOL)cancelJobsOnPrinter:(NSString *)printer error:(NSError *__autoreleasing *)error
{
    int faults = 0;
    NSArray *jobs = [OCPrintJob jobsForPrinter:printer];
    for (OCPrintJob *job in jobs) {
        if (![job cancel])
            faults++;
    }
    if (faults > 0)
        return [OCError errorWithCode:kPrinterErrorProblemCancelingJobs error:error];
    return YES;
}

#pragma mark - Enable / Disable
- (BOOL)enablePrinter:(NSString *)printer
{
    return [self enablePrinter:printer error:nil];
}

- (BOOL)enablePrinter:(NSString *)printer error:(NSError *__autoreleasing *)error
{
    return [self changeStateOfPrinter:printer to:IPP_PRINTER_IDLE error:error];
}

- (BOOL)disablePrinter:(NSString *)printer
{
    return [self disablePrinter:printer error:nil];
}

- (BOOL)disablePrinter:(NSString *)printer error:(NSError *__autoreleasing *)error
{
    return [self changeStateOfPrinter:printer to:IPP_PRINTER_STOPPED error:error];
}

- (BOOL)changeStateOfPrinter:(NSString *)printer to:(int)state error:(NSError *__autoreleasing *)error
{
    ipp_t *request = ippNewRequest(CUPS_ADD_MODIFY_PRINTER);

    char uri[HTTP_MAX_URI];

    httpAssembleURIf(HTTP_URI_CODING_ALL, uri, sizeof(uri), "ipp", NULL,
                     "localhost", 0, "/printers/%s", printer.UTF8String);

    ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_URI, "printer-uri", NULL, uri);
    ippAddInteger(request, IPP_TAG_PRINTER, IPP_TAG_ENUM, "printer-state", state);

    ippDelete(cupsDoRequest(CUPS_HTTP_DEFAULT, request, "/admin/"));

    if (cupsLastError() > IPP_OK_CONFLICT) {
        [OCError cupsError:error];
        return NO;
    }

    return YES;
}

#pragma mark - Printing
- (OCPrintJob *)sendFileAtURL:(NSURL *)file toPrinter:(NSString *)printer
{
    return [self sendFileAtURL:file toPrinter:printer error:nil];
}
- (OCPrintJob *)sendFileAtURL:(NSURL *)file toPrinter:(NSString *)printer error:(NSError *__autoreleasing *)error
{
    return [self sendFile:file.path toPrinter:printer error:error];
}

- (OCPrintJob *)sendFile:(NSString *)file toPrinter:(NSString *)printer
{
    return [self sendFile:file toPrinter:printer error:nil];
}

- (OCPrintJob *)sendFile:(NSString *)file toPrinter:(NSString *)printer error:(NSError *__autoreleasing *)error
{
    OCPrintJob *job = [OCPrintJob new];
    job.dest = printer;
    [job addFile:file];
    [job submit:error];
    return job;
}

- (void)sendFile:(NSString *)file toPrinter:(NSString *)printer failure:(void (^)(NSError *error))failure watch:(void (^)(NSString *, NSInteger))watch
{
    NSError *error;
    OCPrintJob *job = [OCPrintJob new];
    job.dest = printer;
    job.jobMonitor = self;
    _jobStatus = watch;
    [job addFile:file];
    if (![job submit:&error]) {
        job.jobMonitor = nil;
        failure(error);
    }
}

#pragma mark - Class Methods
+ (NSArray *)ppdsForModel:(NSString *)model
{
    return [self ppdsForModel:model error:nil];
}

+ (NSArray *)ppdsForModel:(NSString *)model error:(NSError *__autoreleasing *)error
{
    NSMutableArray *ppdArray = [[NSMutableArray alloc] init];
    ipp_t *request, /* IPP Request */
        *response; /* IPP Response */

    ipp_attribute_t *attr; /* Current attribute */
    const char *ppd_name; /* Filte path to the PPD*/

    request = ippNewRequest(CUPS_GET_PPDS);
    if (model) {
        ippAddString(request, IPP_TAG_OPERATION, IPP_TAG_TEXT, "ppd-make-and-model",
                     NULL, model.UTF8String);
    } else {
        return nil;
    }

    if ((response = cupsDoRequest(CUPS_HTTP_DEFAULT, request, "/")) != NULL) {
        if (ippGetStatusCode(response) > IPP_OK_CONFLICT) {
            [OCError cupsError:error];
            ippDelete(response);
            return nil;
        }

        for (attr = ippFirstAttribute(response); attr != NULL; attr = ippNextAttribute(response)) {
            while (attr != NULL && ippGetGroupTag(attr) != IPP_TAG_PRINTER)
                attr = ippNextAttribute(response);

            if (attr == NULL)
                break;

            ppd_name = NULL;

            while (attr != NULL && ippGetGroupTag(attr) == IPP_TAG_PRINTER) {
                if (!strcmp(ippGetName(attr), "ppd-name") && ippGetValueTag(attr) == IPP_TAG_NAME)
                    ppd_name = ippGetString(attr, 0, NULL);

                attr = ippNextAttribute(response);
            }

            if (ppd_name == NULL) {
                if (attr == NULL)
                    break;
                else
                    continue;
            }
            NSString *ppd_file_path = [NSString stringWithFormat:@"/%s", ppd_name];
            [ppdArray addObject:ppd_file_path];

            if (attr == NULL)
                break;
        }

        ippDelete(response);
    } else {
        NSLog(@"Error Retreving PPD: %s", cupsLastErrorString());
    }

    return ppdArray;
}

+ (NSSet *)installedPrinters
{
    NSMutableSet *set;
    NSString *state_msg;

    cups_dest_t *dests;
    int num_dests;

    ipp_t *request,
        *response;

    const char *printer,
        *uri,
        *device,
        *description,
        *location,
        *model;

    ipp_attribute_t *attr;

    static const char *attrs[] = {
        "printer-name",
        "printer-uri-supported",
        "printer-type",
        "printer-info",
        "printer-make-and-model",
        "printer-location",
        "printer-state-message",
        "printer-state",
        "device-uri",
    };

    dests = NULL;

    set = [NSMutableSet new];
    num_dests = cupsGetDests(&dests);

    if (num_dests == 0) {
        cupsFreeDests(num_dests, dests);
        return nil;
    }

    request = ippNewRequest(CUPS_GET_PRINTERS);

    ippAddStrings(request, IPP_TAG_OPERATION, IPP_TAG_KEYWORD,
                  "requested-attributes", sizeof(attrs) / sizeof(attrs[0]),
                  NULL, attrs);

    response = cupsDoRequest(CUPS_HTTP_DEFAULT, request, "/");

#ifdef __MAC_10_9
    if (cupsLastError() == IPP_STATUS_ERROR_BAD_REQUEST || cupsLastError() == IPP_STATUS_ERROR_VERSION_NOT_SUPPORTED || cupsLastError() > IPP_STATUS_OK_CONFLICTING)
#else
    if (cupsLastError() == IPP_BAD_REQUEST || cupsLastError() == IPP_VERSION_NOT_SUPPORTED || cupsLastError() > IPP_OK_CONFLICT)
#endif
    {
        ippDelete(response);
        return nil;
    }

    if (response) {
        for (attr = ippFirstAttribute(response); attr != NULL; attr = ippNextAttribute(response)) {
            while (attr != NULL && ippGetGroupTag(attr) != IPP_TAG_PRINTER)
                attr = ippNextAttribute(response);

            if (attr == NULL)
                break;

            state_msg = NULL;
            printer = NULL;
            device = NULL;
            uri = NULL;
            location = NULL;
            model = NULL;
            description = NULL;

            while (attr != NULL && ippGetGroupTag(attr) == IPP_TAG_PRINTER) {
                if (!strcmp(ippGetName(attr), "printer-name") && ippGetValueTag(attr) == IPP_TAG_NAME)
                    printer = ippGetString(attr, 0, NULL);

                if (!strcmp(ippGetName(attr), "printer-uri-supported") && ippGetValueTag(attr) == IPP_TAG_URI)
                    uri = ippGetString(attr, 0, NULL);

                if (!strcmp(ippGetName(attr), "device-uri") && ippGetValueTag(attr) == IPP_TAG_URI)
                    device = ippGetString(attr, 0, NULL);

                if (!strcmp(ippGetName(attr), "printer-make-and-model") && ippGetValueTag(attr) == IPP_TAG_TEXT)
                    model = ippGetString(attr, 0, NULL);

                if (!strcmp(ippGetName(attr), "printer-info") && ippGetValueTag(attr) == IPP_TAG_TEXT)
                    description = ippGetString(attr, 0, NULL);

                if (!strcmp(ippGetName(attr), "printer-location") && ippGetValueTag(attr) == IPP_TAG_TEXT)
                    location = ippGetString(attr, 0, NULL);

                attr = ippNextAttribute(response);
            }

            if (printer == NULL) {
                if (attr == NULL)
                    break;
                else
                    continue;
            }

            OCPrinter *p = [OCPrinter new];
            if (printer != NULL)
                p.name = [NSString stringWithUTF8String:printer];
            if (description != NULL)
                p.description = [NSString stringWithUTF8String:description];
            if (location != NULL)
                p.location = [NSString stringWithUTF8String:location];
            if (model != NULL)
                p.model = [NSString stringWithUTF8String:model];
            if (device != NULL) {
                p.uri = [NSString stringWithUTF8String:device];
                NSURL *url = [NSURL URLWithString:p.uri];
                p.protocol = url.scheme;
                p.host = url.host;
            }
            if (uri != NULL) {
                //do something with uri
            }

            [set addObject:p];
            if (attr == NULL)
                break;
        }

        ippDelete(response);
    }
    return set;
}

+ (NSSet *)namesOfInstalledPrinters
{
    NSSet *set = [[self class] installedPrinters];
    NSMutableSet *pNames = [[NSMutableSet alloc] initWithCapacity:set.count];
    for (OCPrinter *p in set) {
        [pNames addObject:p.name];
    }
    return pNames;
}

+ (NSArray *)optionsForModel:(NSString *)model
{
    NSArray *ppdlist = [self ppdsForModel:model];
    if (ppdlist.count > 0) {
        return [self optionsForPPD:ppdlist[0]];
    }
    return nil;
}

+ (NSArray *)optionsForPPD:(NSString *)file
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
        NSLog(@"%s", cupsLastErrorString());
        unlink(file.UTF8String);
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
    unlink(file.UTF8String);
    return array;
}
@end
