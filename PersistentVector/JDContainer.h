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

@property (nonatomic, readonly) NSUInteger count;

+(instancetype)container;
+(instancetype)containerWithObject:(id)o;
+(instancetype)containerWithContainer:(JDContainer*)c;

-(instancetype)init;
-(void)addObject:(id)o;
-(instancetype)copy;
-(id)objectAtIndexedSubscript:(NSUInteger)idx;
-(void)setObject:(id)o atIndexedSubscript:(NSUInteger)idx;

@end
