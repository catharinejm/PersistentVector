//
//  JDAtomicReference.h
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JDAtomicReference : NSObject

@property (atomic, assign) id val;

+(instancetype)referenceWithVal:(id)val;
-(instancetype)initWithVal:(id)val;

@end
