//
//  Utility.h
//  Objective-CUPS
//
//  Created by Eldon on 3/3/14.
//  Copyright (c) 2014 Loyola University New Orleans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <cups/cups.h>

const char *writeOptionsToPPD(cups_option_t *options,
                              int num_options,
                              const char *ppdfile,
                              NSError *__autoreleasing *error);
