//
//  main.swift
//  RepoTools
//
//  Created by Jerry Marino on 4/17/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
import PodToBUILD
import ObjcSupport
import RepoToolsCore

func main() {
    _ = CrashReporter()
    let action = SerializedRepoToolsAction.parse(args: CommandLine.arguments)
    switch action {
    case .initialize(let opts):
        let shell = SystemShellContext(trace: opts.trace)
        RepoActions.initializeRepository(shell: shell, buildOptions: opts)
    case .fetch(let opts):
        let shell = SystemShellContext(trace: opts.trace)
        RepoActions.fetch(shell: shell, fetchOptions: opts)
       break
    }
}

main()
