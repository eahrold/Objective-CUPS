Objective-C framework for interacting with the CUPS system.
The OCPrinter object conforms to NSSecureCoding to be used
with a NSXPC Service and priviledged helper tool so non-admin
users can manage printers themselves.

####Add / Remove OCPrinter
``` Objective-c
NSError *error;

// set up a printer
OCOCPrinter *printer = [OCPrinter new];
printer.name = @"laserjet";
printer.host  = @"mycups.server.com";
printer.protocol = @"ipp";
printer.description = @"LaserJet";
printer.model = @"HP LaserJet 4250";

// add it
CUPSManager *manager = [CUPSManager new]
[manager addOCPrinter:printer error:&error]

// remove it
[manager removeOCPrinter:printer.name error:&error];

// and many more...
```


####Print file
Print file and monitor via Block...
``` Objective-c
[_manager sendFile:@"/tmp/test.txt" toOCPrinter:_printer.name failure:^(NSError *error) {
    NSLog(@"%@",error.localizedDescription);
} watch:^(NSString *status, NSInteger jobID) {
    NSLog(@"%@",status);
}];
```

see [OCManager.h] for more info

[OCManager.h]:./Objective-CUPS/OCManager.h
