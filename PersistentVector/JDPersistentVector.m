//
//  JDPersistentVector.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDPersistentVector.h"

@implementation JDPersistentVector

-(id)initWithCnt:(int)c shift:(int)s root:(JDVectorNode*)r tail:(NSArray*)t {
    self=[super init];
    if (self) {
        _cnt = c;
        _shift = s;
        _root = [r retain];
        _tail = [t retain];
    }
    return self;
}

-(void)dealloc {
    [_root release];
    [_tail release];
    [super dealloc];
}

@end
