//
//  JDContainer.m
//  PersistentVector
//
//  Created by Jon Distad on 1/8/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDContainer.h"

static NSString * const kJDContainerSpaceKey = @"JDContainerSpace";
static NSString * const kJDClaimedObjectsKey = @"JDClaimedObjects";

#define kJDInitialThreshold 32768

static NSHashTableOptions const JDClaimedOptions = (NSHashTableStrongMemory | NSHashTableObjectPointerPersonality);

@interface JDContainerSpace : NSObject
@property (nonatomic) NSUInteger count;
@property (nonatomic) NSUInteger threshold;
@property (nonatomic, retain) NSPointerArray *array;
@end
@implementation JDContainerSpace
-(void)dealloc {
    [_array release];
    [super dealloc];
}
@end

@implementation JDContainer {
    NSPointerArray *_ary;
}

+(JDContainerSpace*)containerSpace {
    JDContainerSpace *sp = [[NSThread currentThread] threadDictionary][kJDContainerSpaceKey];
    if (!sp) {
        sp = [[JDContainerSpace alloc] init];
        sp.count = 0;
        sp.threshold = kJDInitialThreshold;
        sp.array = [NSPointerArray weakObjectsPointerArray];
        [sp.array setCount:kJDInitialThreshold];
        [[NSThread currentThread] threadDictionary][kJDContainerSpaceKey] = sp;
    }

    return sp;
}

+(NSHashTable*)claimedObjects {
    NSHashTable *co = [[NSThread currentThread] threadDictionary][kJDClaimedObjectsKey];
    if (!co) {
        co = [NSHashTable hashTableWithOptions:JDClaimedOptions];
        [[NSThread currentThread] threadDictionary][kJDClaimedObjectsKey] = co;
    }
    return co;
}
+(void)setClaimedObjects:(NSHashTable*)objs {
    [[NSThread currentThread] threadDictionary][kJDClaimedObjectsKey] = objs;
}

+(void)claimObject:(id)o {
    [[JDContainer claimedObjects] addObject:o];
}

+(void)addContainer:(NSPointerArray*)container {
    JDContainerSpace *sp = [JDContainer containerSpace];
    @autoreleasepool {
        if (sp.count > sp.threshold) {
            sp.threshold += sp.threshold;
            
            NSPointerArray *newAry = [NSPointerArray weakObjectsPointerArray];
            [newAry setCount:sp.count];
            for (NSUInteger i = 0; i < sp.count; ++i) {
                void *p = [sp.array pointerAtIndex:i];
                if (p)
                    [newAry replacePointerAtIndex:i withPointer:p];
            }
            [newAry compact];
            sp.count = newAry.count;
            newAry.count = sp.threshold;
            sp.array = newAry;
            
            NSHashTable *newClaim = [NSHashTable hashTableWithOptions:JDClaimedOptions];
            for (NSPointerArray *ary in sp.array) {
                for (id o in ary) {
                    [newClaim addObject:o];
                }
            }
            [JDContainer setClaimedObjects:newClaim]; // Will release old set and all contained objects
        }
    }
    [sp.array replacePointerAtIndex:sp.count withPointer:container];
}

+(instancetype)container {
    return [[[JDContainer alloc] init] autorelease];
}

+(instancetype)containerWithObject:(id)o {
    JDContainer *c = [[[JDContainer alloc] init] autorelease];
    [c addObject:o];
    return c;
}

+(instancetype)containerWithContainer:(JDContainer *)c {
    return [[c copy] autorelease];
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _count = 0;
        _ary = [[NSPointerArray weakObjectsPointerArray] retain];
        [_ary setCount:32];
        [JDContainer addContainer:_ary];
    }
    return self;
}

-(instancetype)initWithPointerArray:(NSPointerArray*)a andCount:(NSUInteger)c {
    self = [super init];
    if (self) {
        _count = c;
        _ary = [a retain];
        [_ary setCount:32];
        [JDContainer addContainer:a];
    }
    return self;
}

-(void)addObject:(id)o {
    [_ary replacePointerAtIndex:_count withPointer:o];
    ++_count;
    [JDContainer claimObject:o];
}

-(id)objectAtIndexedSubscript:(NSUInteger)idx {
    return [_ary pointerAtIndex:idx];
}

-(void)setObject:(id)o atIndexedSubscript:(NSUInteger)idx {
    [_ary replacePointerAtIndex:idx withPointer:o];
    [JDContainer claimObject:o];
}

-(void)dealloc {
    [_ary release];
    [super dealloc];
}

-(JDContainer*)copy {
    NSPointerArray *newAry = [_ary copy];
    [JDContainer addContainer:newAry];
    return [[JDContainer alloc] initWithPointerArray:newAry andCount:_count];
}

@end
