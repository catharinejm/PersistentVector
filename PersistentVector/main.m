//
//  main.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDPersistentVector.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        JDPersistentVector *v = [JDPersistentVector EMPTY];
        NSArray *items = @[@"one", @"two", @"three"];
        
        for (NSString *s in items) {
            JDPersistentVector *newV = [v cons:s];
            [v release];
            v = newV;
        }
        
        for (int i = 0; i < [v count]; ++i) {
            NSLog(@"%d: %@", i, [v nth:i]);
        }
    }
    return 0;
}

