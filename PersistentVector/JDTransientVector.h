//
//  JDTransientVector.h
//  PersistentVector
//
//  Created by Jon Distad on 1/5/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDIVector.h"
#import "JDVectorNode.h"

@class JDPersistentVector;

@interface JDTransientVector : NSObject <JDIVector>

@property (nonatomic, readonly) unsigned cnt;
@property (nonatomic, readonly) unsigned shift;
@property (nonatomic, readonly) JDVectorNode *root;
@property (nonatomic, readonly) NSMutableArray *tail;

+(instancetype)vectorWithVector:(id<JDIVector>)vec;
-(instancetype)initWithCnt:(unsigned)c shift:(unsigned)s root:(JDVectorNode*)r tail:(NSMutableArray*)t;

-(JDPersistentVector*)persistent;

@end
