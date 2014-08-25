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

@interface Objective_CUPSTests : XCTestCase

@end

@implementation Objective_CUPSTests {
    CUPSManager *_manager;
    Printer *_printer;
    PrintJob *_printjob;
    int i;
}

- (void)setUp
{
    [super setUp];
    [self setUpPrinter];
    _manager = [CUPSManager sharedManager];
    // Put setup code here. This method is called before the invocation of each test method in the class.
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

- (void)testAddPrinter
{
    NSError *error;
    _printer.options = @[ @"HPOption_Tray4=Tray4_500", @"HPOption_Tray3=True" ];
    XCTAssertTrue([_manager addPrinter:_printer error:&error], @"Add Printer Error: %@", error);
}

- (void)testAvaliableOptions
{
    NSLog(@"%@", [_printer avaliableOptions]);
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
    [_printjob addFiles:@[ @"/tmp/test.txt", @"/tmp/test.txt" ]];
    sleep(1);
    XCTAssertTrue([_printjob submit:&error], @"Print Job Error: %@", error);
}

- (void)testCancelJob
{
    XCTAssertTrue([PrintJob cancelJobNamed:@"test.txt"], @"Cancel Job Error");
}

- (void)testCancelJobOnPrinter
{
    NSError *error;
    XCTAssertTrue([_manager cancelJobsOnPrinter:_printer.name error:&error]);
}

- (void)testOptionsForModel
{
    NSArray *arr = [CUPSManager optionsForModel:_printer.model];
    NSLog(@"%@", arr);
}

- (void)testInstalledPrinters
{
    for (Printer *p in [CUPSManager installedPrinters]) {
        NSLog(@"ppd for printer %@ : %@", p.name, p.ppd);
    }
}
- (void)testPrintJobAndWatch
{
    [_manager sendFile:@"/tmp/test.txt" toPrinter:_printer.name failure:^(NSError *error) {
        XCTAssertNil(error, @"Problem Printing: %@",error.localizedDescription);
        NSLog(@"%@",error.localizedDescription);
        i=5;
    } watch:^(NSString *status, NSInteger jobID) {
        NSLog(@"%@ count:%d",status,i);
        i++;
        if (i > 5)
            [PrintJob cancelJobWithID:jobID];
    }];
}

- (void)testRemovePrinter
{
    NSError *error;
    XCTAssertTrue([_manager removePrinter:_printer.name error:&error], @"Add Printer Error: %@", error);
}

- (void)setUpPrinter
{
    if (!_printer) {
        _printer = [Printer new];
        _printer.name = @"laserjet";
        _printer.host = @"nowhere";
        _printer.protocol = @"ipp";
        _printer.description = @"LaserJet";
        _printer.model = @"HP Color LaserJet CP5220 Series with Duplexer";
    }
}

- (void)setupJob
{
    _printjob = [PrintJob new];
    _printjob.dest = _printer.name;
}

@end
