//
//  JDUtil.m
//  PersistentVector
//
//  Created by Jon Distad on 1/5/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import "JDUtil.h"

JDVectorNode *newPath(JDAtomicReference *edit, unsigned level, JDVectorNode *node) {
    if (level == 0)
        return [node retain];
    JDVectorNode *ret = [[JDVectorNode alloc] initWithEdit:edit];
    JDVectorNode *np = newPath(edit, level - 5, node);
    [ret.array addObject:np];
    [np release];
    return ret;
}
