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
        JDAtomicReference *noEdit = [[JDAtomicReference alloc] initWithVal:nil];
        _EMPTY_NODE = [[JDVectorNode alloc] initWithEdit: noEdit
                                                  array:[NSMutableArray arrayWithCapacity:32]];
        [noEdit release];
    });
    return [_EMPTY_NODE retain];
}

+(JDPersistentVector*)EMPTY {
    static JDPersistentVector *_EMPTY = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _EMPTY = [[JDPersistentVector alloc] initWithCnt:0 shift:5 root:[JDPersistentVector EMPTY_NODE] tail:[NSMutableArray array]];
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

-(NSMutableArray*)arrayFor:(unsigned int)i {
    if (i < self.cnt) {
        if (i >= [self tailoff])
            return self.tail;
        JDVectorNode *node = self.root;
        for (int level = (int)self.shift; level > 0; level -= 5)
            node = (JDVectorNode*)node.array[(i >> level) & 0x01f];
        return node.array;
    }
    @throw [NSException exceptionWithName:NSRangeException
                                   reason:[NSString stringWithFormat:@"index %d out of bounds", i]
                                 userInfo:nil];
}

-(id)nth:(unsigned int)i {
    id v = [self arrayFor:i][i & 0x01f];
    if (v == [NSNull null]) return nil;
    return v;
}

-(id)nth:(unsigned int)i notFound:(id)nf {
    [nf autorelease]; // TODO: Is this appropriate? I figure caller will want to retain the return val regardless of what it is.
    if (i < self.cnt)
        return [self nth:i];
    return nf;
}

JDVectorNode *doAssoc(unsigned level, JDVectorNode *node, unsigned i, id val) {
    NSMutableArray *ary = [node.array mutableCopy];
    JDVectorNode *ret = [[JDVectorNode alloc] initWithEdit:node.edit array:ary];
    [ary release];
    
    if (level == 0)
        ret.array[i & 0x01f] = (val != nil ? val : [NSNull null]);
    else {
        int subidx = (i >> level) & 0x01f;
        JDVectorNode *n = doAssoc(level - 5, (JDVectorNode*)node.array[subidx], i, val);
        ret.array[subidx] = n;
        [n release];
    }
    return ret;
}

-(instancetype)assocN:(unsigned int)i object:(id)val {
    if (i < self.cnt) {
        if (i >= [self tailoff]) {
            NSMutableArray *newTail = [self.tail mutableCopy];
            newTail[i & 0x01f] = (val != nil ? val : [NSNull null]);
            JDPersistentVector *v = [[JDPersistentVector alloc] initWithCnt:self.cnt
                                                                       shift:self.shift
                                                                        root:self.root
                                                                        tail:newTail];
            [newTail release];
            return v;
        }
        JDVectorNode *newRoot = doAssoc(self.shift, self.root, i, val);
        JDPersistentVector *v = [[JDPersistentVector alloc] initWithCnt:self.cnt
                                                                  shift:self.shift
                                                                   root:newRoot
                                                                   tail:self.tail];
        [newRoot release];
        return v;
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
    NSMutableArray *ary = [parent.array mutableCopy];
    JDVectorNode *ret = [[JDVectorNode alloc] initWithEdit:parent.edit array:ary];
    [ary release];
    JDVectorNode *nodeToInsert;
    if (level == 5) {
        [ret.array addObject:tailnode];
        return ret;
    }
    if (subidx >= parent.array.count)
        nodeToInsert = newPath(self.root.edit, level-5, tailnode);
    else
        nodeToInsert = [self pushTailAt:level-5 parent:(JDVectorNode*)parent.array[subidx] tail:tailnode];
    
    [ret.array addObject:nodeToInsert];
    [nodeToInsert release];
    return ret;
}

-(instancetype)cons:(id)val {
    // Room in tail?
    if (self.cnt - [self tailoff] < 32) {
        NSMutableArray *newTail = [self.tail mutableCopy];
        [newTail addObject:(val != nil ? val : [NSNull null])];
        JDPersistentVector *v = [[JDPersistentVector alloc] initWithCnt:self.cnt + 1
                                                                  shift:self.shift
                                                                   root:self.root
                                                                   tail:newTail];
        [newTail release];
        return v;
    }
    // Full tail, push into tree
    JDVectorNode *newroot;
    NSMutableArray *tail = [self.tail mutableCopy];
    JDVectorNode *tailnode = [[JDVectorNode alloc] initWithEdit:self.root.edit array:tail];
    [tail release];
                              
    unsigned newshift = self.shift;
    // Overflow root?
    if ((self.cnt >> 5) > (1 << self.shift)) {
        newroot = [[JDVectorNode alloc] initWithEdit:self.root.edit];
        [newroot.array addObject:self.root];
        JDVectorNode *np = newPath(self.root.edit, self.shift, tailnode);
        [newroot.array addObject:np];
        [np release];
        newshift += 5;
    } else
        newroot = [self pushTailAt:self.shift parent:self.root tail:tailnode];

    [tailnode release];

    NSMutableArray *newTail = [[NSMutableArray alloc] initWithObjects:(val != nil ? val : [NSNull null]), nil];
    JDPersistentVector *ret = [[JDPersistentVector alloc] initWithCnt:self.cnt + 1 shift:newshift root:newroot tail:newTail];
    [newTail release];
    [newroot release];
    return ret;
}

@end
