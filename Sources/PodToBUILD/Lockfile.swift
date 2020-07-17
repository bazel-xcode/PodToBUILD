/// A swift representation of the yaml described here.
// https://github.com/CocoaPods/Core/blob/master/lib/cocoapods-core/lockfile.rb#L349
///   {
///    'PODS'             => [ { BananaLib (1.0) => [monkey (< 1.0.9, ~> 1.0.1)] },
///                            "JSONKit (1.4)",
///                            "monkey (1.0.8)"]
///    'DEPENDENCIES'     => [ "BananaLib (~> 1.0)",
///                            "JSONKit (from `path/JSONKit.podspec`)" ],
///    'EXTERNAL SOURCES' => { "JSONKit" => { :podspec => path/JSONKit.podspec } },
///    'SPEC CHECKSUMS'   => { "BananaLib" => "439d9f683377ecf4a27de43e8cf3bce6be4df97b",
///                            "JSONKit", "92ae5f71b77c8dec0cd8d0744adab79d38560949" },
///    'PODFILE CHECKSUM' => "439d9f683377ecf4a27de43e8cf3bce6be4df97b",
///    'COCOAPODS'        => "0.17.0"
///  }

import Foundation
import Yams

public struct Lockfile {
    var pods: [Any] = []
    var dependencies: [String] = []
    var externalSources: [String: [String: String]] = [:]
    var specRepos: [String: [String]] = [:]
    var specChecksums: [String: String] = [:]
    var podfileChecksum: String = ""
    var cocoapods: String = ""

    public init(data: Data) throws {
        let loadedDictionary = try Yams.load(yaml: String(data: data, encoding:
            .utf8)!) as! [String: Any]
        guard let cocoapodsval = loadedDictionary["COCOAPODS"] as? String else {
            fatalError("Invalid lockfile")
        }
        cocoapods = cocoapodsval
        specRepos = loadedDictionary["SPEC REPOS"] as? [String: [String]] ?? [:]
        externalSources = loadedDictionary["EXTERNAL SOURCES"] as? [String:
            [String: String]] ?? [:]
        dependencies = loadedDictionary["DEPENDENCIES"] as? [String] ?? []
        specChecksums = loadedDictionary["SPEC CHECKSUMS"] as? [String: String] ?? [:]
        podfileChecksum = loadedDictionary["PODFILE CHECKSUM"] as? String ?? ""
        pods = loadedDictionary["PODS"] as? [Any] ?? []

    }
}
