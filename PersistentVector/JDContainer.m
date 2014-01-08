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

-(instancetype)init {
    self = [super init];
    if (self) {
        _ary = [[NSPointerArray weakObjectsPointerArray] retain];
        [JDContainer addContainer:_ary];
    }
    return self;
}

-(instancetype)initWithArray:(NSPointerArray*)a {
    self = [super init];
    if (self) {
        _ary = [a retain];
        [JDContainer addContainer:a];
    }
    return self;
}

-(void)addObject:(id)o {
    NSHashTable *ht = [JDContainer claimedObjects];
    [_ary addPointer:o];
    [ht addObject:o];
}

-(void)dealloc {
    [_ary release];
    [super dealloc];
}

-(JDContainer*)copy {
    NSPointerArray *newAry = [_ary copy];
    [JDContainer addContainer:newAry];
    return [[JDContainer alloc] initWithArray:newAry];
}

@end
