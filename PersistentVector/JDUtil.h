//
//  JDUtil.h
//  PersistentVector
//
//  Created by Jon Distad on 1/5/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDVectorNode.h"
#import "JDAtomicReference.h"

//#define kPVShiftStep 5
//#define kPVNodeCapacity 32
//#define kPVTailMask 0x01f
#define kPVShiftStep 5
#define kPVNodeCapacity (1 << kPVShiftStep)
#define kPVTailMask (kPVNodeCapacity-1)

JDVectorNode *newPath(JDAtomicReference *edit, unsigned level, JDVectorNode *node);