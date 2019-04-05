//
//  WCLProcessFilter.m
//  SevenHup
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//
#import "SUPProcesses.h"
#import "Constants.h"

#include <assert.h>
#include <errno.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>

typedef struct kinfo_proc kinfo_proc;

#pragma mark - C

static int GetBSDProcessForIdentifier(struct kinfo_proc *kinfo, pid_t pid) {
    u_int miblen = 4;
    size_t len;
    int mib[miblen];
    int res;

    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = pid;
    len = sizeof(struct kinfo_proc);
    res = sysctl(mib, miblen, kinfo, &len, NULL, 0);
    return res;
}

#pragma mark - SUPProcesses

@implementation SUPProcesses

+ (NSDictionary *)identifierToProcessesForIdentifiers:(NSArray<NSNumber *> *)identifiers {
    NSMutableDictionary *identifierToProcessInfo = [NSMutableDictionary dictionary];
    for (NSNumber *identifier in identifiers) {
        pid_t pid = identifier.intValue;
        struct kinfo_proc kinfo;
        int err;
        err = GetBSDProcessForIdentifier(&kinfo, pid);
        if (err != 0) {
            continue;
        }

        NSMutableDictionary *processDictionary = [NSMutableDictionary dictionary];

        NSNumber *processIdentifierNumber = [NSNumber numberWithInt:kinfo.kp_proc.p_pid];
        if (processIdentifierNumber != identifier) {
            // It appears that in some cases a process that doesn't match is
            // returned. This might only be in the case where a `pid` no longer
            // exists?
            continue;
        }

        assert(identifier == processIdentifierNumber);
        NSString *processIdentifier = processIdentifierNumber.stringValue;
        if (processIdentifier) {
            processDictionary[kProcessIdentifierKey] = processIdentifier;
        }
        NSString *processName = [NSString stringWithFormat:@"%s", kinfo.kp_proc.p_comm];
        if (processName) {
            processDictionary[kProcessNameKey] = processName;
        }

        NSTimeInterval timeInterval = kinfo.kp_proc.p_starttime.tv_sec + kinfo.kp_proc.p_starttime.tv_usec / 1.e6;
        NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        if (startTime) {
            processDictionary[kProcessStartTimeKey] = startTime;
        }

        struct passwd *user = getpwuid(kinfo.kp_eproc.e_ucred.cr_uid);
        if (user) {
            // TODO: Fix this inefficient convert from `NSNumber` to `NSString`.
            NSNumber *userIdentifierNumber = [NSNumber numberWithUnsignedInt:kinfo.kp_eproc.e_ucred.cr_uid];
            NSString *userIdentifier = userIdentifierNumber.stringValue;
            if (userIdentifier) {
                processDictionary[kProcessUserIdentifierKey] = userIdentifier;
            }
            NSString *userName = [NSString stringWithFormat:@"%s", user->pw_name];
            if (userName) {
                processDictionary[kProcessUsernameKey] = userName;
            }
        }

        identifierToProcessInfo[processIdentifier] = processDictionary;
    }
    return identifierToProcessInfo;
}

@end
