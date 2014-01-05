//
//  JDIVector.h
//  PersistentVector
//
//  Created by Jon Distad on 1/5/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JDIVector <NSObject>

-(instancetype)conj:(id)obj;

-(NSArray*)arrayFor:(unsigned)i;

-(id)nth:(unsigned)i;
-(id)nth:(unsigned)i notFound:(id)nf;
-(instancetype)assocN:(unsigned)i object:(id)val;

-(unsigned)count;

-(instancetype)cons:(id)val;

@end
