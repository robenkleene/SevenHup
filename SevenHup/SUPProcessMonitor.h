//
//  SUPProcessMonitor.h
//  Web Console
//
//  Created by Roben Kleene on 1/5/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface SUPProcessMonitor : NSObject
- (instancetype)initWithIdentifier:(int)identifier;
@property (nonatomic, readonly) BOOL isRunning;
- (void)watchWithCompletionHandler:(void (^)(BOOL success))completionHandler;
@end
NS_ASSUME_NONNULL_END