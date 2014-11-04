//
//  Employment.m
//  eIndberetning
//
//  Created by Jacob Hansen on 27/10/14.
//  Copyright (c) 2014 IT-Minds. All rights reserved.
//

#import "Employment.h"
#import "CDEmployment.h"

@implementation Employment

+ (NSArray *) initFromJsonDic:(NSDictionary*)dic;
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    for (NSDictionary* employment in dic) {
        Employment* e = [[Employment alloc] init];
        e.employmentPosition = [[employment objectForKey:@"EmploymentPosition"] description];
        e.employmentId = @([[employment objectForKey:@"id"] integerValue]);
        [array insertObject:e atIndex:0];
    }
    
    return array;
}

+ (NSArray *) initFromCoreDataArray:(NSArray*)CDArray
{
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity: CDArray.count];
    
    for (CDEmployment *CDe in CDArray)
    {
        Employment* emp = [[Employment alloc] init];
        
        emp.employmentPosition = CDe.employmentposition;
        emp.employmentId = CDe.employmentid;
        
        [array insertObject:emp atIndex:0];
    }
    
    return array;
}

-(void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.employmentPosition forKey:@"employmentPosition"];
    [encoder encodeObject:self.employmentId forKey:@"employmentId"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.employmentPosition = [decoder decodeObjectForKey:@"employmentPosition"];
        self.employmentId = [decoder decodeObjectForKey:@"employmentId"];
    }
    return self;
}

- (BOOL)isEqual:(Employment*)object
{
    return([self.employmentPosition isEqualToString:object.employmentPosition] && [self.employmentId isEqualToNumber:object.employmentId] );
}
@end
