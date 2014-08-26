###Objective-C framework for interacting with CUPS.

The OCPrinter object conforms to NSSecureCoding to be used
with a NSXPC Service and priviledged helper tool so non-admin users can manage printers themselves.

####Add / Remove OCPrinter
``` Objective-c
NSError *error;

// set up a printer
OCPrinter *printer = [OCPrinter new];
printer.name = @"laserjet";
printer.host  = @"mycups.server.com";
printer.protocol = @"ipp";
printer.description = @"LaserJet";
printer.model = @"HP LaserJet 4250";

// add it
OCManager *manager = [CUPSManager new]
[manager addPrinter:printer error:&error]

// remove it
[manager removePrinter:printer.name error:&error];

// and many more...
```


####Print file
Print file and monitor via Block...
``` Objective-c
[_manager sendFile:@"/tmp/test.txt" toPrinter:_printer.name failure:^(NSError *error) {
    NSLog(@"%@",error.localizedDescription);
} watch:^(NSString *status, NSInteger jobID) {
    NSLog(@"%@",status);
}];
```

see [OCManager.h] for more info

[OCManager.h]:./Objective-CUPS/OCManager.h
