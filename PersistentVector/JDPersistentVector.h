//
//  JDPersistentVector.h
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDVectorNode.h"
#import "JDIVector.h"
#import "JDContainer.h"

@class JDTransientVector;

@interface JDPersistentVector : NSObject <JDIVector>

@property (nonatomic, readonly) unsigned cnt;
@property (nonatomic, readonly) unsigned shift;
@property (nonatomic, readonly) JDVectorNode *root;
@property (nonatomic, readonly) JDContainer *tail;

+(JDVectorNode*)EMPTY_NODE;
+(JDPersistentVector*)EMPTY;

+(instancetype)createWithArray:(NSArray*)items;
-(instancetype)initWithCnt:(unsigned)c shift:(unsigned)s root:(JDVectorNode*)r tail:(JDContainer*)t;

-(JDTransientVector*)asTransient;

@end

