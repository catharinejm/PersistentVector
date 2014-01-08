//
//  JDContainer.h
//  PersistentVector
//
//  Created by Jon Distad on 1/8/14.
//  Copyright (c) 2014 Jon Distad. All rights reserved.
//

#import <Foundation/Foundation.h>

id *JDNewContainer();

@interface JDContainer : NSObject

-(instancetype)init;
-(instancetype)initWithArray:(NSPointerArray*)a;
-(void)addObject:(id)o;
-(instancetype)copy;

@end
