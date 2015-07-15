//
//  NSNetService+ReadableTxtRecord.m
//
//  Created by Eldon on 6/22/15.
//
//

#import "NSNetService+ObjectiveCUPS.h"

@implementation NSNetService (ObjectiveCUPS)

- (NSDictionary *)oc_serializedTxtRecord {
    NSData *data = [self TXTRecordData];
    NSDictionary *dict = [NSNetService dictionaryFromTXTRecordData:data];

    NSMutableDictionary *retDict = [[NSMutableDictionary alloc] initWithCapacity:dict.count + 3];

    retDict[@"name"] = [self.name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    retDict[@"description"] = self.name;
    retDict[@"host"] = [self.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSData *data, BOOL *stop) {
        NSString* str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        if (str.length) {
            retDict[key] = str;
        }
    }];

    return retDict;

}
@end
