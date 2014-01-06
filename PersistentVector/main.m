//
//  main.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDPersistentVector.h"
#import "JDTransientVector.h"

int main(int argc, const char * argv[])
{
    for (int q=0;q<10;++q) {
    for (int x = 0; x < 10; ++x) {
        @autoreleasepool {
            
            // insert code here...
            unsigned c = 32801;
//            unsigned c = 1057;
//            unsigned c = 1024;
//            unsigned c = 33;
//            unsigned c = 32;
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:c];
            for (int i = 0; i < c; ++i)
                [items addObject:[NSNumber numberWithInt:i]];

            JDPersistentVector *v = [JDPersistentVector EMPTY];
//            JDPersistentVector *v = [JDPersistentVector createWithArray:items];
//            NSLog(@"%d", [v count]);
            
            unsigned chunksize = 32;
            for (int i = 0; i < items.count; i += chunksize) {
                [v autorelease];
                @autoreleasepool {
                    for (NSNumber *n in [items subarrayWithRange:NSMakeRange(i, (i+chunksize > items.count ? (items.count%chunksize) : chunksize))]) {
                        v = [v cons:n];
                    }
                    [v retain];
                }
            }
            //        JDTransientVector *v = [JDTransientVector vectorWithVector:[JDPersistentVector EMPTY]];
            //        for (NSNumber *n in items) {
            //            [v cons:n];
            //        }
            
//            NSLog(@"count: %u", [v count]);
//            NSLog(@"shift: %u", v.shift);
//            int i;
//            for (i = 0; i < 5; ++i) {
//                NSLog(@"%d: %@", i, [v nth:i]);
//            }
//            for (i = [v count] - 5; i < [v count]; ++i) {
//                NSLog(@"%d: %@", i, [v nth:i]);
//            }
        }
    }
    }
    return 0;
}

