//
//  BasicBuildOptions.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/2/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

struct BasicBuildOptions : BuildOptions {
    let podName: String 
    let userOptions: [String]
    let globalCopts: [String]
    let trace: Bool

    /// Parse in Command Line arguments
    /// Example: PodName --user_option Opt1
    static func parse(args: [String]) -> BasicBuildOptions {
        // First arg is the path, we don't care about it
        var idx = 0
        func error() {
            print("Usage: PodspecName")
            exit(0)
        }

        // The right most option will be the winner.
        var multiOptions = [
            "--user_option" : Set<String>(),
            "--global_copt" : Set<String>(),
            "--trace" : Set<String>()
        ]
        
        func nextArg() -> String {
            if idx + 1 < args.count {
                idx += 1
            } else {
                error()
            }
            return args[idx]
        }

        // There is no flag for the podName of the Pod
        let podName = nextArg()
        while (true) {
            idx += 1
            if (idx < args.count) == false {
                break
            }
            if let _ = multiOptions[args[idx]] {
                multiOptions[args[idx]]!.insert(nextArg())
            } else {
                error()
            }
        } 

        return BasicBuildOptions(podName: podName,
                                 userOptions: Array(multiOptions["--user_option"]!),
                                 globalCopts: Array(multiOptions["--global_copt"]!),
                                 trace: multiOptions["--trace"] != nil
        )
    }
}
