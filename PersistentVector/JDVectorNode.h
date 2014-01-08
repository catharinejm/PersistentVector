//
//  JDVectorNode.h
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDAtomicReference.h"
#import "JDContainer.h"

@interface JDVectorNode : NSObject

@property (nonatomic, retain) JDAtomicReference *edit;
@property (nonatomic, retain) JDContainer *array;

-(id)initWithEdit:(JDAtomicReference*)ed array:(JDContainer*)ary;
-(id)initWithEdit:(JDAtomicReference*)ed;

@end
