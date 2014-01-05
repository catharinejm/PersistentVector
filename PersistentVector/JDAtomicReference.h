//
//  JDAtomicReference.h
//  PersistentVector
//
//  Created by Jon Distad on 1/4/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JDAtomicReference : NSObject

@property (atomic, retain) id val;

-(id)initWithVal:(id)val;

@end
