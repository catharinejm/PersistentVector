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
        return node;
    JDVectorNode *ret = [[[JDVectorNode alloc] initWithEdit:edit] autorelease];
    [ret.array addObject:newPath(edit, level - kPVShiftStep, node)];
    return ret;
}
