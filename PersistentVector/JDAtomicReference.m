//
//  JDAtomicReference.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDAtomicReference.h"

@implementation JDAtomicReference

-(id)initWithVal:(id)val {
    self = [super init];
    if (self) {
        _val = val;
    }
    return self;
}

-(void)dealloc {
    [_val release];
    [super dealloc];
}

@end

