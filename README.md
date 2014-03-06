Objective-C framework for interacting with the CUPS system.
The Printer object conforms to NSSecureCoding to be used
with a NSXPC Service and priviledged helper tool so non-admin
users can manage printers themselves.

####Add / Remove Printer
``` Objective-c
NSError *error;

// set up a printer
Printer *printer = [Printer new];
printer.name = @"laserjet";
printer.host  = @"mycups.server.com";
printer.protocol = @"ipp";
printer.description = @"LaserJet";
printer.model = @"HP LaserJet 4250";

// add it
CUPSManager *manager = [CUPSManager new]
[manager addPrinter:printer error:&error]

// remove it
[manager removePrinter:printer.name error:&error];

// and many more...
```

see [cupsmanger.h] for more info

[cupsmanger.h]:./Objective-CUPS/CUPSManager.h
