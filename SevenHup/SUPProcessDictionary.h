//
//  SUPProcessDictioinary.h
//  SevenHup
//
//  Created by Roben Kleene on 4/5/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// This is an unused slower approach than what's used in `SUPProdcesses.h`, but it might be useful for testing.

@interface SUPProcessDictionary : NSObject
+ (NSDictionary *)identifierToProcessesForIdentifiers:(NSSet<NSNumber *> *)identifiersSet;
@end

NS_ASSUME_NONNULL_END
