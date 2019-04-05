//
//  SUPProcessMonitor.m
//  Web Console
//
//  Created by Roben Kleene on 1/5/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

#import "SUPProcessMonitor.h"

#include <sys/event.h>

@interface SUPProcessMonitor ()
@property (nonatomic, assign) pid_t identifier;
@property (nonatomic) BOOL isTerminated;
@property (nonatomic, copy) void (^completionHandler)(BOOL);
@end

@implementation SUPProcessMonitor

- (instancetype)initWithIdentifier:(pid_t)identifier {
    self = [super init];
    if (self != nil) {
        _identifier = identifier;
    }

    return self;
}

- (void)watchWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    self.completionHandler = completionHandler;

    int queue = kqueue();
    if (queue == -1) {
        [self fireCompletionHandlerWithResult:NO];
        return;
    }

    pid_t identifier = self.identifier;
    struct kevent changes;
    EV_SET(&changes, identifier, EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);

    if (kevent(queue, &changes, 1, &changes, 1, NULL) == -1) {
        [self fireCompletionHandlerWithResult:NO];
        return;
    }

    CFFileDescriptorContext context = {0, (void *)CFBridgingRetain(self), NULL, NULL, NULL};
    CFFileDescriptorRef noteExitKQueueRef = CFFileDescriptorCreate(NULL, queue, true, noteExitKQueueCallback, &context);
    if (noteExitKQueueRef == NULL) {
        CFRelease((__bridge CFTypeRef)(self));
        [self fireCompletionHandlerWithResult:NO];
        return;
    }

    CFRunLoopSourceRef runLoopSource = CFFileDescriptorCreateRunLoopSource(NULL, noteExitKQueueRef, 0);
    if (runLoopSource == NULL) {
        CFRelease((__bridge CFTypeRef)(self));
        [self fireCompletionHandlerWithResult:NO];
        return;
    }

    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    CFRelease(runLoopSource);

    CFFileDescriptorEnableCallBacks(noteExitKQueueRef, kCFFileDescriptorReadCallBack);

    if (self.isTerminated) {
        [self fireCompletionHandlerWithResult:YES];
    }
}

static void noteExitKQueueCallback(CFFileDescriptorRef file, CFOptionFlags __unused callBackTypes, void *info) {
    struct kevent event;
    kevent(CFFileDescriptorGetNativeDescriptor(file), NULL, 0, &event, 1, NULL);

    SUPProcessMonitor *processMonitor = CFBridgingRelease(info);
    processMonitor.isTerminated = YES;
    [processMonitor fireCompletionHandlerWithResult:YES];
}

- (BOOL)isRunning {
    if (self.isTerminated) {
        return YES;
    }

    return kill(self.identifier, 0) == 0;
}

- (void)fireCompletionHandlerWithResult:(BOOL)success {
    if (!self.completionHandler) {
        return;
    }

    void (^completionHandler)(BOOL) = self.completionHandler;
    self.completionHandler = nil;
    completionHandler(success);
}

@end
