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

JDVectorNode *newPath(JDAtomicReference *edit, unsigned level, JDVectorNode *node);