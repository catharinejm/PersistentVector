//
//  JDAtomicReference.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDAtomicReference.h"

@implementation JDAtomicReference

+(instancetype)referenceWithVal:(id)val {
    return [[[JDAtomicReference alloc] initWithVal:val] autorelease];
}

-(instancetype)initWithVal:(id)val {
    self = [super init];
    if (self) {
        _val = val;
    }
    return self;
}

@end

