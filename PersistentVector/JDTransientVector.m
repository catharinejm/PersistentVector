//
//  JDTransientVector.m
//  PersistentVector
//
//  Created by Jon Distad on 1/5/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDTransientVector.h"
#import "JDPersistentVector.h"

JDVectorNode *editableRoot(JDVectorNode *node) {
    return [[JDVectorNode alloc] initWithEdit:[JDAtomicReference referenceWithVal:[NSThread currentThread]]
                                        array:[[node.array copy] autorelease]];
}

NSMutableArray *editableTail(NSArray *tail) {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:32];
    [ret addObjectsFromArray:tail];
    return ret;
}

@implementation JDTransientVector

#pragma mark - Initializers

+(instancetype)vectorWithVector:(JDPersistentVector*)vec {
    return [[JDTransientVector alloc] initWithCnt:vec.cnt
                                            shift:vec.shift
                                             root:editableRoot(vec.root)
                                             tail:editableTail(vec.tail)];
}

-(instancetype)initWithCnt:(unsigned)c shift:(unsigned)s root:(JDVectorNode*)r tail:(NSMutableArray*)t {
    self=[super init];
    if (self) {
        _cnt = c;
        _shift = s;
        _root = [r retain];
        _tail = [t retain];
    }
    return self;
}

#pragma mark - Persistent

-(JDPersistentVector*)persistent {
    [self ensureEditable];
    self.root.edit.val = nil;
    NSArray *trimmedTail = [NSArray arrayWithArray:self.tail];
    return [[JDPersistentVector alloc] initWithCnt:self.cnt shift:self.shift root:self.root tail:trimmedTail];
}

#pragma mark - Util

-(void)ensureEditable {
    NSThread *owner = self.root.edit.val;
    if (owner == [NSThread currentThread])
        return;
    if (owner != nil)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Transient used by non-owner thread."
                                     userInfo:nil];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Transient used after persistent! call"
                                 userInfo:nil];
}

-(JDVectorNode*)ensureEditableNode:(JDVectorNode*)node {
    if (node.edit == self.root.edit)
        return node;
    return [[JDVectorNode alloc] initWithEdit:self.root.edit array:[[node.array copy] autorelease]];
}

#pragma mark - Dealloc

-(void)dealloc {
    [_root release];
    [_tail release];
    [super dealloc];
}


@end
