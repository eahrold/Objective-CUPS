//
//  main.m
//  test-cli
//
//  Created by Eldon on 3/4/14.
//  Copyright (c) 2014 Loyola University New Orleans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Objective-CUPS.h"

BOOL ka;

int main(int argc, const char *argv[])
{

    @autoreleasepool
    {
        ka = YES;
        CUPSManager *manager = [CUPSManager new];
        //        PrintJob *p = [manager sendFile:@"/tmp/test.txt" toPrinter:@"laserjet"];

        [manager sendFile:@"/tmp/test.txt" toPrinter:@"laserjet" failure:^(NSError *error) {
            NSLog(@"%@",error.localizedDescription);
        } watch:^(NSString *status, NSInteger jobID) {
            NSLog(@"%@ and ka = %d",status,ka);
            //            if([status isEqualToString:@"complete"])
            //                ka = NO;
        }];
        while (ka) {
            //            NSLog(@"%@ and ka = %d",p,ka);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        }

        NSLog(@"done");
    }
    return 0;
}
