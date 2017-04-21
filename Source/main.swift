import Foundation

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

    let buildFile = PodBuildFile.with(podSpec: podSpec)
    let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.skylarkConvertibles.flatMap { $0.toSkylark() })
    print(buildFileSkylarkCompiler.run())
}

main()
