//
//  CDRate.h
//  eIndberetning
//
//  Created by Jacob Hansen on 14/12/14.
//  Copyright (c) 2014 IT-Minds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDRate : NSManagedObject

@property (nonatomic, retain) NSNumber * rateid;
@property (nonatomic, retain) NSString * rateDescription;
@property (nonatomic, retain) NSDate * year;

@end
