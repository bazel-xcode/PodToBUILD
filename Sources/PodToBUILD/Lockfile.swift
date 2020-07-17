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
    // FIXME: complete impl, spec
    var pods: [Any] = []
    var dependencies: [String] = []
    var externalSources: [String: [String: String]] = [:]
    var specChecksums: [String] = []
    var podfileChecksum: String = ""
    var cocoapods: String = ""

    public init(data: Data) throws {
        /// Don't use codeable for simplicity to handle the dynamic nature of this
        let loadedDictionary = try Yams.load(yaml: String(data: data, encoding:
            .utf8)!) as! [String: Any]
        // FIXME: complete impl, spec
        guard let externalDepsYams = loadedDictionary["EXTERNAL SOURCES"] as? [String:
            [String: String]] else {
            fatalError("Missing deps")
        }
        externalSources = externalDepsYams
        guard let depsYams = loadedDictionary["PODS"] as? [Any] else {
            fatalError("Missing deps" + String(describing: loadedDictionary["PODS"]))
        }
        pods = depsYams
    }
}
