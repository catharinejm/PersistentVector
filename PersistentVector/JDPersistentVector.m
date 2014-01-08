//
//  JDPersistentVector.m
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDPersistentVector.h"
#import "JDTransientVector.h"
#import "JDUtil.h"

@interface JDPersistentVector ()

@property (nonatomic, readonly) JDVectorNode *EMPTY_NODE;
@property (nonatomic, readonly) JDPersistentVector *EMPTY;

@end

@implementation JDPersistentVector
@dynamic EMPTY_NODE;
@dynamic EMPTY;

#pragma mark - Empty Constants

+(JDVectorNode*)EMPTY_NODE {
    static JDVectorNode *_EMPTY_NODE = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _EMPTY_NODE = [[JDVectorNode alloc] initWithEdit:[[[JDAtomicReference alloc] initWithVal:nil] autorelease]
                                                  array:[NSPointerArray strongObjectsPointerArray]];
    });
    return [_EMPTY_NODE retain];
}

+(JDPersistentVector*)EMPTY {
    static JDPersistentVector *_EMPTY = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _EMPTY = [[JDPersistentVector alloc] initWithCnt:0 shift:5 root:[JDPersistentVector EMPTY_NODE] tail:[NSPointerArray strongObjectsPointerArray]];
    });
    return [_EMPTY retain];
}

#pragma mark - Initializers

+(instancetype)createWithArray:(NSArray*)items {
    JDTransientVector *ret = [[JDPersistentVector EMPTY] asTransient];
    for (id o in items)
        ret = [ret cons:o];
    return [ret persistent];
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

#pragma mark - Dealloc

-(void)dealloc {
    [_root release];
    [_tail release];
    [super dealloc];
}

#pragma mark - Transient

-(JDTransientVector*)asTransient {
    return [JDTransientVector vectorWithVector:self];
}

#pragma mark - Util

-(unsigned)tailoff {
    if (self.cnt < 32)
        return 0;
    return ((self.cnt - 1) >> 5) << 5;
}

-(NSPointerArray*)arrayFor:(unsigned int)i {
    if (i < self.cnt) {
        if (i >= [self tailoff])
            return self.tail;
        JDVectorNode *node = self.root;
        for (int level = (int)self.shift; level > 0; level -= 5)
            node = [((JDVectorNode*)node).array pointerAtIndex:(i >> level) & 0x01f];
        return node.array;
    }
    @throw [NSException exceptionWithName:NSRangeException
                                   reason:[NSString stringWithFormat:@"index %d out of bounds", i]
                                 userInfo:nil];
}

-(id)nth:(unsigned int)i {
    return [[self arrayFor:i] pointerAtIndex:i & 0x01f];
}

-(id)nth:(unsigned int)i notFound:(id)nf {
    if (i < self.cnt)
        return [self nth:i];
    return [nf autorelease];
}

JDVectorNode *doAssoc(unsigned level, JDVectorNode *node, unsigned i, id val) {
    JDVectorNode *ret = [[JDVectorNode alloc] initWithEdit:node.edit array:[[node.array copy] autorelease]];
    if (level == 0)
        [ret.array replacePointerAtIndex:(i & 0x01f) withPointer:val];
    else {
        int subidx = (i >> level) & 0x01f;
        [ret.array replacePointerAtIndex:subidx
                             withPointer:doAssoc(level - 5,
                                                 [((JDVectorNode*)node).array pointerAtIndex:subidx],
                                                 i,
                                                 val)];
    }
    return [ret autorelease];
}

-(instancetype)assocN:(unsigned int)i object:(id)val {
    if (i < self.cnt) {
        if (i >= [self tailoff]) {
            NSPointerArray *newTail = [NSPointerArray strongObjectsPointerArray];
            [newTail replacePointerAtIndex:(i & 0x01f) withPointer:val];
            return [[[JDPersistentVector alloc] initWithCnt:self.cnt
                                                     shift:self.shift
                                                      root:self.root
                                                      tail:newTail]
                    autorelease];
        }
        return [[[JDPersistentVector alloc] initWithCnt:self.cnt
                                                 shift:self.shift
                                                  root:doAssoc(self.shift, self.root, i, val)
                                                  tail:self.tail]
                autorelease];
    }
    if (i == self.cnt)
        return [self cons:val];
    @throw [NSException exceptionWithName:NSRangeException
                                   reason:[NSString stringWithFormat:@"index %d out of range", i]
                                 userInfo:nil];
}

-(unsigned)count {
    return self.cnt;
}

-(JDVectorNode*)pushTailAt:(unsigned)level parent:(JDVectorNode*)parent tail:(JDVectorNode*)tailnode {
    int subidx = ((self.cnt - 1) >> level) & 0x01f;
    JDVectorNode *ret = [[JDVectorNode alloc] initWithEdit:parent.edit array:[[parent.array copy] autorelease]];
    JDVectorNode *nodeToInsert;
    if (level == 5)
        nodeToInsert = tailnode;
    else {
        if (subidx >= parent.array.count)
            nodeToInsert = newPath(self.root.edit, level-5, tailnode);
        else
            nodeToInsert = [self pushTailAt:level-5
                                     parent:[((JDVectorNode*)parent).array pointerAtIndex:subidx]
                                       tail:tailnode];
    }
    [ret.array addPointer:nodeToInsert];
    return [ret autorelease];
}

-(instancetype)cons:(id)val {
    // Room in tail?
    if (self.cnt - [self tailoff] < 32) {
        NSPointerArray *newTail = [[self.tail copy] autorelease];
        [newTail addPointer:val];
        return [[[JDPersistentVector alloc] initWithCnt:self.cnt + 1
                                                 shift:self.shift
                                                  root:self.root
                                                  tail:newTail]
                autorelease];
    }
    // Full tail, push into tree
    JDVectorNode *newroot;
    JDVectorNode *tailnode = [[[JDVectorNode alloc] initWithEdit:self.root.edit
                                                          array:[[self.tail copy] autorelease]]
                              autorelease];
                              
    unsigned newshift = self.shift;
    // Overflow root?
    if ((self.cnt >> 5) > (1 << self.shift)) {
        newroot = [[[JDVectorNode alloc] initWithEdit:self.root.edit] autorelease];
        [newroot.array addPointer:self.root];
        [newroot.array addPointer:newPath(self.root.edit, self.shift, tailnode)];
        newshift += 5;
    } else
        newroot = [self pushTailAt:self.shift parent:self.root tail:tailnode];
    NSPointerArray *newTail = [NSPointerArray strongObjectsPointerArray];
    [newTail addPointer:val];
    return [[[JDPersistentVector alloc] initWithCnt:self.cnt + 1 shift:newshift root:newroot tail:newTail] autorelease];
}

@end
