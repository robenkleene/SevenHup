//
//  SUPProcesses.h
//  SevenHup
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface SUPProcesses : NSObject
+ (NSDictionary *)identifierToProcessesForIdentifiers:(NSArray<NSNumber *> *)identifiers;
@end
NS_ASSUME_NONNULL_END
