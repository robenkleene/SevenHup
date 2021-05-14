# `SevenHup` ![Status](https://github.com/robenkleene/sevenhup/actions/workflows/ci.yml/badge.svg) ![Status](https://github.com/robenkleene/sevenhup/actions/workflows/release.yml/badge.svg)

`SevenHup` is a child process manager for tracking child processes and providing functionality for cleaning them up all at once.

## Compiling

`SevenHup` uses [Carthage](https://github.com/Carthage/Carthage), so before compiling, run `carthage update`.

## Initialization

``` swift
let processManager = ProcessManager(processManagerStore: userDefaults)
```

- `processManagerStore`: Storage for process metadata

## Example

Adding a process:

```
let processData = ProcessData(identifier: identifier,
                              name: commandPath,
                              userIdentifier: uid,
                              username: username,
                              startTime: startTime)
processManager.add(processData)
```

Terminating and removing all running processes:

``` swift
processManager.killAndRemoveRunningProcessDatas { identifierToProcessData, error in
    // Finish processing
}
```

