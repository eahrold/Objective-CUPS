//
//  NSNetService+ReadableTxtRecord.h
//  Pods
//
//  Created by Eldon on 6/22/15.
//
//

#import <Foundation/Foundation.h>

@interface NSNetService (ObjectiveCUPS)
@property (copy, nonatomic, readonly) NSDictionary *oc_serializedTxtRecord;
@end
