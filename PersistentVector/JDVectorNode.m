//
//  JDVectorNode.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDVectorNode.h"

@implementation JDVectorNode

-(id)initWithEdit:(JDAtomicReference*)ed array:(NSMutableArray*)ary {
    self = [super init];
    if (self) {
        _edit = [ed retain];
        _array = [ary retain];
    }
    return self;
}

-(id)initWithEdit:(JDAtomicReference*)ed {
    self = [super init];
    if (self) {
        _edit = [ed retain];
        _array = [NSMutableArray arrayWithCapacity:32];
    }
    return self;
}

-(void)dealloc {
    [_edit release];
    [_array release];
    [super dealloc];
}

@end