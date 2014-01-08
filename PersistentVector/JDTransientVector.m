//
//  JDTransientVector.m
//  PersistentVector
//
//  Created by Jon Distad on 1/5/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDTransientVector.h"
#import "JDPersistentVector.h"
#import "JDUtil.h"

JDVectorNode *editableRoot(JDVectorNode *node) {
    return [[[JDVectorNode alloc] initWithEdit:[JDAtomicReference referenceWithVal:[NSThread currentThread]]
                                        array:[[node.array copy] autorelease]]
            autorelease];
}

NSPointerArray *editableTail(NSPointerArray *tail) {
    return [[tail copy] autorelease];
}

@implementation JDTransientVector

#pragma mark - Initializers

+(instancetype)vectorWithVector:(JDPersistentVector*)vec {
    return [[[JDTransientVector alloc] initWithCnt:vec.cnt
                                            shift:vec.shift
                                             root:editableRoot(vec.root)
                                             tail:editableTail(vec.tail)]
            autorelease];
}

-(instancetype)initWithCnt:(unsigned)c shift:(unsigned)s root:(JDVectorNode*)r tail:(NSPointerArray*)t {
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
    return [[[JDPersistentVector alloc] initWithCnt:self.cnt shift:self.shift root:self.root tail:[[self.tail copy] autorelease]]
            autorelease];
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
    return [[[JDVectorNode alloc] initWithEdit:self.root.edit array:[[node.array copy] autorelease]] autorelease];
}

-(unsigned)tailoff {
    if (self.cnt < 32)
        return 0;
    return ((self.cnt-1) >> 5) << 5;
}

-(NSPointerArray*)arrayFor:(unsigned)i {
    if (i < self.cnt) {
        if (i >= [self tailoff])
            return self.tail;
        JDVectorNode *node = self.root;
        for (int level = (int)self.shift; level > 0; level -= 5)
            node = [((JDVectorNode*)node).array pointerAtIndex:(i >> level) & 0x01f];
        return node.array;
    }
    @throw [NSException exceptionWithName:NSRangeException
                                   reason:[NSString stringWithFormat:@"index %du out of bounds", i]
                                 userInfo:nil];
}

-(NSPointerArray*)editableArrayFor:(unsigned)i {
    if (i < self.cnt) {
        if (i >= [self tailoff])
            return self.tail;
        JDVectorNode *node = self.root;
        for (int level = (int)self.shift; level > 0; level -= 5)
            node = [self ensureEditableNode:[((JDVectorNode*)node).array pointerAtIndex:(i >> level) & 0x01f]];
        return node.array;
    }
    @throw [NSException exceptionWithName:NSRangeException
                                   reason:[NSString stringWithFormat:@"index %d out of bounds", i]
                                 userInfo:nil];
}

-(JDVectorNode*)pushTailAt:(unsigned)level parent:(JDVectorNode*)parent tail:(JDVectorNode*)tailnode {
    parent = [self ensureEditableNode:parent];
    unsigned subidx = ((self.cnt - 1) >> level) & 0x01f;
    JDVectorNode *ret = parent;
    JDVectorNode *nodeToInsert;
    if (level == 5)
        nodeToInsert = tailnode;
    else {
        if (subidx >= parent.array.count)
            nodeToInsert = newPath(self.root.edit, level - 5, tailnode);
        else
            nodeToInsert = [self pushTailAt:level - 5 parent:[((JDVectorNode*)parent).array pointerAtIndex:subidx] tail:tailnode];
    }
    [ret.array addPointer:nodeToInsert];
    return ret;
}

-(instancetype)cons:(id)val {
    [self ensureEditable];
    int i = self.cnt;
    // room in tail?
    if (i - [self tailoff] < 32) {
        [self.tail addPointer:val];
         _cnt++;
        return self;
    }
    // Full tail, push into tree
    JDVectorNode *newroot;
    JDVectorNode *tailnode = [[[JDVectorNode alloc] initWithEdit:self.root.edit array:self.tail] autorelease];
    self.tail = [NSPointerArray strongObjectsPointerArray];
    [self.tail addPointer:val];
    unsigned newshift = self.shift;
    
    // Overflow root?
    if ((self.cnt >> 5) > (1 << self.shift)) {
        newroot = [[[JDVectorNode alloc] initWithEdit:self.root.edit] autorelease];
        [newroot.array addPointer:self.root];
        [newroot.array addPointer:newPath(self.root.edit, self.shift, tailnode)];
        newshift += 5;
    } else
        newroot = [self pushTailAt:self.shift parent:self.root tail:tailnode];
    self.root = newroot;
    self.shift = newshift;
    self.cnt++;
    return self;
}

-(id)nth:(unsigned)i {
    [self ensureEditable];
    return [[self arrayFor:i] pointerAtIndex:i & 0x01f];
}

-(id)nth:(unsigned int)i notFound:(id)nf {
    if (i < self.cnt)
        return [self nth:i];
    return [nf autorelease];
}

-(JDVectorNode*)doAssocAt:(unsigned)level node:(JDVectorNode*)node index:(unsigned)i object:(id)val {
    node = [self ensureEditableNode:node];
    JDVectorNode *ret = node;
    if (level == 0)
        [ret.array replacePointerAtIndex:(i & 0x01f) withPointer:val];
    else {
        unsigned subidx = (i >> level) & 0x01f;
        [ret.array replacePointerAtIndex:subidx withPointer:[self doAssocAt:level - 5 node:[((JDVectorNode*)node).array pointerAtIndex:subidx] index:i object:val]];
    }
    return ret;
}

-(instancetype)assocN:(unsigned int)i object:(id)val {
    [self ensureEditable];
    if (i < self.cnt) {
        if (i >= [self tailoff]) {
            [self.tail replacePointerAtIndex:i & 0x01f withPointer:val];
            return self;
        }
        
        self.root = [self doAssocAt:self.shift node:self.root index:i object:val];
        return self;
    }
    if (i == self.cnt)
        return [self cons:val];
    @throw [NSException exceptionWithName:NSRangeException
                                   reason:[NSString stringWithFormat:@"index %du is out of bounds", i]
                                 userInfo:nil];
}

-(unsigned)count {
    [self ensureEditable];
    return self.cnt;
}

#pragma mark - Dealloc

-(void)dealloc {
    [_root release];
    [_tail release];
    [super dealloc];
}


@end
