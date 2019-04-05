//
//  SUPProcessDictioinary.m
//  SevenHup
//
//  Created by Roben Kleene on 4/5/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

#import "SUPProcessDictionary.h"
#import "Constants.h"

#include <assert.h>
#include <errno.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysctl.h>

typedef struct kinfo_proc kinfo_proc;

@implementation SUPProcessDictionary

static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int err;
    kinfo_proc *result;
    bool done;
    static const int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t length;

    assert(procList != NULL);
    assert(*procList == NULL);
    assert(procCount != NULL);

    *procCount = 0;

    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.

    result = NULL;
    done = false;
    do {
        assert(result == NULL);

        // Call sysctl with a NULL buffer.

        length = 0;
        err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, NULL, &length, NULL, 0);
        if (err == -1) {
            err = errno;
        }

        // Allocate an appropriately sized buffer based on the results
        // from the previous call.

        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }

        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.

        if (err == 0) {
            err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, result, &length, NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && !done);

    // Clean up and establish post conditions.

    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }

    assert((err == 0) == (*procList != NULL));

    return err;
}

+ (NSDictionary *)identifierToProcessesForIdentifiers:(NSSet<NSNumber *> *)identifiersSet {
    kinfo_proc *list = NULL;
    size_t count = 0;
    GetBSDProcessList(&list, &count);

    NSMutableDictionary *identifierToProcessInfo = [NSMutableDictionary dictionaryWithCapacity:(int)count];

    for (int i = 0; i < count; i++) {
        struct kinfo_proc *proc = &list[i];
        NSMutableDictionary *processDictionary = [NSMutableDictionary dictionaryWithCapacity:4];

        NSNumber *processIdentifierNumber = [NSNumber numberWithInt:proc->kp_proc.p_pid];
        // TODO: This manual iteration of every process is inefficient, ideally
        // this would be modified to instead have `GetBSDProcessList` take a
        // list of identifiers and only return those (not sure if this is
        // possible)
        if (![identifiersSet containsObject:processIdentifierNumber]) {
            continue;
        }

        NSString *processIdentifier = processIdentifierNumber.stringValue;
        if (processIdentifier) {
            processDictionary[kProcessIdentifierKey] = processIdentifier;
        }
        NSString *processName = [NSString stringWithFormat:@"%s", proc->kp_proc.p_comm];
        if (processName) {
            processDictionary[kProcessNameKey] = processName;
        }

        NSTimeInterval timeInterval = proc->kp_proc.p_starttime.tv_sec + proc->kp_proc.p_starttime.tv_usec / 1.e6;
        NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:timeInterval];
        if (startTime) {
            processDictionary[kProcessStartTimeKey] = startTime;
        }

        struct passwd *user = getpwuid(proc->kp_eproc.e_ucred.cr_uid);
        if (user) {
            // TODO: Fix this inefficient convert from `NSNumber` to `NSString`.
            NSNumber *userIdentifierNumber = [NSNumber numberWithUnsignedInt:proc->kp_eproc.e_ucred.cr_uid];
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
    free(list);

    return identifierToProcessInfo;
}

@end
