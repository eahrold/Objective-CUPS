//
//  PrinterJob.m
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
#import "OCPrintJob.h"
#import "OCError.h"
#import <cups/cups.h>

@interface OCPrintJob () {
@private
    NSMutableArray *_files;
    BOOL _submitted;
}

@property (copy, nonatomic, readwrite) NSString *statusDescription;
@property (readwrite, nonatomic) OSStatus status;
@property (nonatomic) NSInteger size;
@end

#pragma mark - PrintJob
@implementation OCPrintJob

- (void)dealloc
{
    NSLog(@"deallocated job: %ld", [self jid]);
}

- (id)init
{
    self = [super init];
    if (self) {
        _name = @"no title";
        _user = @"unknown";
        _jid = 0;
        _size = 0;
        _submitionDate = 0;
        _submitted = NO;
        _statusDescription = @"unknown";
    }
    return self;
}

- (id)initWithJob_t:(cups_job_t *)job index:(int)i
{
    self = [self init];
    if (self && job != NULL) {
        _name = [NSString stringWithUTF8String:job[i].title];
        _dest = [NSString stringWithUTF8String:job[i].dest];
        _jid = job[i].id;
        _size = job[i].size;
        _submitionDate = job[i].creation_time;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"JobID: %ld Name:%@ dest:%@ -- %@ Size:%ld", (long)_jid, _name, _dest, self.statusDescription, (long)self.size];
}

- (BOOL)cancel
{
    return [self cancel:nil];
}

- (BOOL)cancel:(NSError *__autoreleasing *)error
{
    http_t *http; /* HTTP connection to server */
    ipp_status_t status;

#ifdef __MAC_10_9
    http = httpConnect2(cupsServer(), ippPort(), NULL, 0, cupsEncryption(), 0, 0, NULL);
#else
    http = httpConnect(cupsServer(), ippPort());
#endif

    if (http == NULL)
        return [OCError cupsError:error];

    status = cupsCancelJob(_dest.UTF8String, (int)_jid);

#ifdef __MAC_10_9
    if (status != IPP_STATUS_OK)
#else
    if (status == IPP_OK || status == IPP_OK_SUBST)
#endif
    {
        return YES;
    }
    return [OCError cupsError:error];
}

- (void)addFiles:(NSArray *)files
{
    for (NSString *file in files) {
        [self addFile:file];
    }
}
- (void)addFile:(NSString *)file
{
    if (!_files) {
        _files = [NSMutableArray new];
    }
    [_files addObject:file];
}

- (BOOL)submit
{
    return [self submit:nil];
}

- (BOOL)submit:(NSError *__autoreleasing *)error
{
    if (_submitted)
        return [OCError errorWithCode:kPrintJobAlreaySubmitted error:error];
    else if (!_files)
        return [OCError errorWithCode:kPrintJobNoFileSubmitted error:error];

    _submitted = YES;
    _name = [(NSString *)_files[0] lastPathComponent];

    int i = (int)_files.count;
    int num_files = 0;
    const char *files[1000];

    for (NSString *f in _files) {
        files[num_files] = f.UTF8String;
        num_files++;
    }

    _jid = cupsPrintFiles(_dest.UTF8String, i, files, _name.UTF8String, 0, NULL);
    if (_jid == 0) {
        return [OCError cupsError:error];
    }

    if (_jobMonitor) {
        ipp_jstate_t job_state = IPP_JOB_PENDING;
        while (job_state < IPP_JOB_COMPLETED) {
            job_state = self.status;
            [_jobMonitor didRecieveStatusUpdate:self.statusDescription job:self];
            if (job_state < IPP_JOB_STOPPED)
                sleep(2);
        }
    }
    return YES;
}

- (BOOL)start
{
    return [self start:nil];
}

- (BOOL)start:(NSError *__autoreleasing *)error
{
    return YES;
}

- (BOOL)hold
{
    return [self hold:nil];
}

- (BOOL)hold:(NSError *__autoreleasing *)error
{
    return YES;
}

#pragma mark - Accessors
- (OSStatus)status
{
    _status = [self statusForJobID:_jid dest:_dest];
    return _status;
}

- (NSString *)statusDescription
{
    _statusDescription = [self statusDescriptionForStatus:self.status];
    return _statusDescription;
}

- (NSInteger)size
{
    int num_jobs;
    cups_job_t *jobs;
    int i;
    ipp_jstate_t job_state = IPP_JOB_PENDING;

    while (job_state < IPP_JOB_STOPPED) {
        num_jobs = cupsGetJobs(&jobs, _dest.UTF8String, 1, -1);
        job_state = IPP_JOB_COMPLETED;

        for (i = 0; i < num_jobs; i++)
            if (jobs[i].id == _jid) {
                _size = jobs[i].size;
                break;
            }

        /* Free the job array */
        cupsFreeJobs(num_jobs, jobs);
    }
    return _size;
}

#pragma mark - Monitoring
- (OSStatus)statusForJobID:(NSInteger)jid dest:(NSString *)dest
{
    OSStatus status = 0;
    int num_jobs;
    cups_job_t *jobs;
    int i;

    num_jobs = cupsGetJobs(&jobs, dest.UTF8String, 1, CUPS_WHICHJOBS_ACTIVE);
    status = IPP_JOB_COMPLETED;

    for (i = 0; i < num_jobs; i++)
        if (jobs[i].id == jid) {
            status = jobs[i].state;
            break;
        }
    cupsFreeJobs(num_jobs, jobs);

    return status;
}

- (NSString *)statusDescriptionForStatus:(OSStatus)status
{
    NSString *statusDescription;
    switch (status) {
    case IPP_JOB_PENDING:
        statusDescription = @"pending";
        break;
    case IPP_JOB_HELD:
        statusDescription = @"held";
        break;
    case IPP_JOB_PROCESSING:
        statusDescription = @"processing";
        break;
    case IPP_JOB_STOPPED:
        statusDescription = @"stopped";
        break;
    case IPP_JOB_CANCELED:
        statusDescription = @"canceled";
        break;
    case IPP_JOB_ABORTED:
        statusDescription = @"aborted";
        break;
    case IPP_JOB_COMPLETED:
        statusDescription = @"complete";
        break;
    }
    return statusDescription;
}

#pragma mark - Class Methods
+ (NSArray *)jobsForAllPrinters
{
    return [self jobsForAllPrinterIncludingCompleted:NO];
}

+ (NSArray *)jobsForAllPrinterIncludingCompleted:(BOOL)includeCompleted
{
    return [self jobsForPrinter:@"" includeCompleted:includeCompleted];
}

+ (NSArray *)jobsForPrinter:(NSString *)printer
{
    return [self jobsForPrinter:printer includeCompleted:NO];
}

+ (NSArray *)jobsForPrinter:(NSString *)printer includeCompleted:(BOOL)include
{
    int which;
    if (include)
        which = CUPS_WHICHJOBS_ALL;
    else
        which = CUPS_WHICHJOBS_ACTIVE;
    return [self getJobs:printer which:which];
}

+ (NSArray *)getJobs:(NSString *)printer which:(int)which
{
    NSMutableArray *jobArray;

    cups_job_t *jobs;
    int i;
    int num_jobs;

    num_jobs = cupsGetJobs(&jobs, printer.UTF8String, 0, which);
    if (num_jobs <= 0) {
        return nil;
    };

    jobArray = [[NSMutableArray alloc] initWithCapacity:num_jobs];
    for (i = 0; i < num_jobs; i++) {
        OCPrintJob *job = [[OCPrintJob alloc] initWithJob_t:jobs index:i];
        [jobArray addObject:job];
    }

    cupsFreeJobs(num_jobs, jobs);
    return jobArray;
}

+ (void)cancelAllJobs
{
    for (OCPrintJob *job in [self jobsForAllPrinters]) {
        [job cancel];
    }
}

+ (BOOL)cancelJobWithID:(NSInteger)jid
{
    return [self cancelJobWithID:jid error:nil];
}

+ (BOOL)cancelJobWithID:(NSInteger)jid error:(NSError *__autoreleasing *)error
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jid == %d", jid];
    return [self cancelJobWithPredicate:predicate error:error];
}

+ (BOOL)cancelJobNamed:(NSString *)name
{
    return [self cancelJobNamed:name error:nil];
}

+ (BOOL)cancelJobNamed:(NSString *)name error:(NSError *__autoreleasing *)error
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    return [self cancelJobWithPredicate:predicate error:error];
}

+ (BOOL)cancelJobWithPredicate:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error
{
    BOOL rc = NO;
    NSArray *jobs = [self jobsForAllPrinters];
    for (OCPrintJob *job in jobs) {
        if ([predicate evaluateWithObject:job]) {
            rc = [job cancel];
        }
    }
    return rc;
}
@end
