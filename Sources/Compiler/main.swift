import Foundation
import PodToBUILD

func main() {
    if CommandLine.arguments.count < 2 {
        // First, print a JSON rep of a Pod spec
        // pod spec cat PINCache
        print("Usage: somePodspec.json")
        exit(0)
    }

    let JSONPodspecFile = CommandLine.arguments[1]
    guard let jsonData = NSData(contentsOfFile: JSONPodspecFile) as Data?,
        let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict,
        let podSpec = try? PodSpec(JSONPodspec: JSONPodspec)
    else {
        fatalError("Invalid JSON Podspec: \(JSONPodspecFile)")
    }

    let podSpecURL = NSURL(fileURLWithPath: JSONPodspecFile)
    let assumedPodName = podSpecURL.lastPathComponent!.components(separatedBy: ".")[0]
    let options = BasicBuildOptions(podName: assumedPodName,
                                 userOptions: [String](),
                                 globalCopts: [String](),
                                 trace: false,
                                 enableModules: false,
                                 generateModuleMap: false,
                                 headerVisibility:  "",
                                 alwaysSplitRules: true)

    // Consider adding a split here to split out sublibs
    let buildFile = PodBuildFile.with(podSpec: podSpec, buildOptions: options)
    let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.toSkylark())
    print(buildFileSkylarkCompiler.run())
}

main()
