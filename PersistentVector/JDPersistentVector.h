//
//  JDPersistentVector.h
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDVectorNode.h"

@interface JDPersistentVector : NSObject

@property (nonatomic, readonly) int cnt;
@property (nonatomic, readonly) int shift;
@property (nonatomic, readonly) JDVectorNode *root;
@property (nonatomic, readonly) NSArray *tail;

@end

