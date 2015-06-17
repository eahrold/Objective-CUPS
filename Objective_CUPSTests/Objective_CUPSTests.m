//
//  Objective_CUPSTests.m
//  Objective_CUPSTests
//
//  Created by Eldon on 1/22/14.
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

#import <XCTest/XCTest.h>
#import "Objective-CUPS.h"
#import <cups/cups.h>

static NSString *const _tmpFile = @"/tmp/test.txt";

@interface Objective_CUPSTests : XCTestCase

@end

@implementation Objective_CUPSTests {
    OCManager *_manager;
    OCPrinter *_printer;
    OCPrintJob *_printjob;
    int i;
}

- (void)setUp
{
    [super setUp];
    [self setUpPrinter];
    _manager = [OCManager sharedManager];

    [[@"Hello World !" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:_tmpFile atomically:YES];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)setUpPrinter
{
    if (!_printer) {
        _printer = [OCPrinter new];
        _printer.name = @"laserjet";
        _printer.host = @"pretendco.com";
        _printer.protocol = kOCProtocolHTTPS;
        _printer.description = @"LaserJet";
        _printer.model = @"HP Color LaserJet CP5220 Series with Duplexer";
    }
}

- (void)setupJob
{
    _printjob = [OCPrintJob new];
    _printjob.dest = _printer.name;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAll;
{

    [self testAddPrinter];
    [self testAddOption];
    [self testStatus];
    [self testPrintFileFromPrinter];
    [self testCancelJob];
    [self testPrintJobAndWatch];
    [self testRemovePrinter];
}

- (void)testGetPPD
{
    http_t *server = NULL;

    server = httpConnect("mdm.masscomm.loyno.edu", 631);

    time_t now;
    http_status_t status;
    char * buffer;


    buffer = (char*) malloc (MAXPATHLEN);
    status = cupsGetPPD3(server, "bw324", &now, buffer, MAXPATHLEN);
    if(status != HTTP_STATUS_ERROR){
        NSString *path = [NSString stringWithUTF8String:buffer].stringByStandardizingPath;
        NSLog(@"Found file %@", path);
    } else {
        NSLog(@"%s", cupsLastErrorString());
    }
    free(buffer);

}

- (void)testAddPrinter
{
    NSError *error;
    _printer.options = @[ @"HPOption_Tray4=Tray4_500", @"HPOption_Tray3=True" ];
    XCTAssertTrue([_manager addPrinter:_printer error:&error], @"Add Printer Error: %@", error);
}

- (void)testAvaliableOptions
{
    NSLog(@"%@", [_printer availableOptions]);
}

- (void)testAddOption
{
    XCTAssertTrue([_manager addOptions:@[ @"HPOption_Tray3=Tray3_500" ] toPrinter:_printer.name], @"Add Option Error:");
}

- (void)testStatus
{
    NSLog(@"%@", _printer.statusMessage);
    XCTAssertNotEqual(_printer.status, 0, @"Bad Status:");
}

- (void)testPrintFileFromPrinter
{
    NSError *error;
    XCTAssertTrue([_manager sendFile:@"/tmp/test.txt" toPrinter:_printer.name error:&error], @"Printing Error: %@", error);
}

- (void)testPrintFilesFromJob
{
    NSError *error;
    [self setupJob];
    [_printjob addFiles:@[ _tmpFile ]];
    sleep(1);
    XCTAssertTrue([_printjob submit:&error], @"Print Job Error: %@", error);
}

- (void)testCancelJob
{
    XCTAssertTrue([OCPrintJob cancelJobNamed:_tmpFile.lastPathComponent], @"Cancel Job Error");
}

- (void)testCancelJobOnPrinter
{
    NSError *error;
    XCTAssertTrue([_manager cancelJobsOnPrinter:_printer.name error:&error]);
}

- (void)testOptionsForModel
{
    NSArray *arr = [OCManager optionsForModel:_printer.model];
    NSLog(@"%@", arr);
}

- (void)testInstalledPrinters
{
    for (OCPrinter *p in [OCManager installedPrinters]) {
        NSLog(@"ppd for printer %@ : %@", p.name, p.ppd);
    }
}

- (void)testPrintJobAndWatch
{
    XCTestExpectation *expect = [self expectationWithDescription:@"watch"];

    [_manager sendFile:_tmpFile toPrinter:_printer.name failure:^(NSError *error) {
        XCTAssertNil(error, @"Problem Printing: %@",error.localizedDescription);
        NSLog(@"%@",error.localizedDescription);
        i=5;
    } watch:^(NSString *status, NSInteger jobID) {
        NSLog(@"%@ count:%d", status, i);
        i++;
        if (i > 5){
            if ([OCPrintJob cancelJobWithID:jobID]) {
                [expect fulfill];
            };
        }
    }];

    [self waitForExpectationsWithTimeout:300 handler:^(NSError *error) {
        if(error)
        {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testRemovePrinter
{
    NSError *error;
    XCTAssertTrue([_manager removePrinter:_printer.name error:&error], @"Add Printer Error: %@", error);
}

@end
