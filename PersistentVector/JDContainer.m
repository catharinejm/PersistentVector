//
//  JDContainer.m
//  PersistentVector
//
//  Created by Jon Distad on 1/8/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDContainer.h"

static NSString * const kJDContainerSpaceKey = @"JDContainerSpace";
static NSString * const kJDContainerThresholdKey = @"JDContainerThreshold";
static NSString * const kJDClaimedObjectsKey = @"JDClaimedObjects";

#define kJDInitialThreshold 32768

static NSHashTableOptions const JDClaimedOptions = (NSHashTableStrongMemory | NSHashTableObjectPointerPersonality);

@implementation JDContainer {
    NSPointerArray *_ary;
}

@dynamic count;

+(NSPointerArray*)containerSpace {
    NSPointerArray *sp = [[NSThread currentThread] threadDictionary][kJDContainerSpaceKey];
    if (!sp) {
        sp = [NSPointerArray weakObjectsPointerArray];
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

+(unsigned long)containerThreshold {
    NSNumber *ct = [[NSThread currentThread] threadDictionary][kJDContainerThresholdKey];
    if (!ct) {
        ct = [NSNumber numberWithUnsignedLong:kJDInitialThreshold];
        [[NSThread currentThread] threadDictionary][kJDContainerThresholdKey] = ct;
    }
    return ct.unsignedLongValue;
}
+(void)setContainerThreshold:(unsigned long)v {
    [[NSThread currentThread] threadDictionary][kJDContainerThresholdKey] = [NSNumber numberWithUnsignedLong:v];
}

+(void)claimObject:(id)o {
    [[JDContainer claimedObjects] addObject:o];
}

+(void)addContainer:(NSPointerArray*)container {
    NSPointerArray *sp = [JDContainer containerSpace];
    unsigned long threshold = [JDContainer containerThreshold];
    @autoreleasepool {
        if (sp.count > threshold) {
            threshold += threshold;
            
            [sp compact];

            while (sp.count >= threshold)
                threshold += threshold;
            
            NSHashTable *newClaim = [NSHashTable hashTableWithOptions:JDClaimedOptions];
            for (NSPointerArray *ary in sp) {
                for (id o in ary) {
                    [newClaim addObject:o];
                }
            }
            [JDContainer setClaimedObjects:newClaim]; // Will release old set and all contained objects
            [JDContainer setContainerThreshold:threshold];
        }
    }
    [sp addPointer:container];
}

+(instancetype)container {
    return [[[JDContainer alloc] init] autorelease];
}

+(instancetype)containerWithObject:(id)o {
    JDContainer *c = [[[JDContainer alloc] init] autorelease];
    [c addObject:o];
    return c;
}

+(instancetype)containerWithObjects:(id)o, ... {
    if (o) {
        NSPointerArray *ary = [NSPointerArray weakObjectsPointerArray];
        va_list objs;
        va_start(objs, o);
        for (id x = o; x != nil; x = va_arg(objs, id)) {
            [ary addPointer:x];
        }
        return [[[JDContainer alloc] initWithPointerArray:ary] autorelease];
    }
    return [[[JDContainer alloc] init] autorelease];
}

+(instancetype)containerWithContainer:(JDContainer *)c {
    return [[c copy] autorelease];
}

+(instancetype)containerWithPointerArray:(NSPointerArray *)a {
    return [[[JDContainer alloc] initWithPointerArray:a] autorelease];
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _ary = [[NSPointerArray weakObjectsPointerArray] retain];
        [JDContainer addContainer:_ary];
    }
    return self;
}

-(instancetype)initWithPointerArray:(NSPointerArray*)a {
    self = [super init];
    if (self) {
        _ary = [a retain];
        [JDContainer addContainer:a];
    }
    return self;
}

-(NSUInteger)count {
    return _ary.count;
}

-(void)addObject:(id)o {
    [_ary addPointer:o];
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
    return [[JDContainer alloc] initWithPointerArray:newAry];
}

@end
