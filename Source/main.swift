import Foundation

// Render a Bazel WORKSPACE entry with a buildfile inline
func renderWorkspaceEntry(podspec _: PodSpec, JSONPodspec: JSONDict, buildFileString: String) {
    // @note this needs some work. We now rely on new_pod_repository and this
    // has been refactored out of the program.
    let repo = try! NewGitRepository(JSONPodspec: JSONPodspec)
    let repoSkylark = SkylarkNode.functionCall(name: "new_git_repository", arguments: [
        .named(name: "name", value: .string(value: repo.name)),
        .named(name: "remote", value: .string(value: repo.remote)),
        .named(name: "tag", value: .string(value: repo.tag)),
        .named(name: "build_file_content", value: .multiLineString(value: "\n\(buildFileString)")),
    ])
    let compiler = SkylarkCompiler([repoSkylark])
    print(compiler.run())
}

func main() {
    if CommandLine.arguments.count < 2 {
        // First, print a JSON rep of a Pod spec
        // pod spec cat PINCache
        print("Usage: somePodspec.json")
        exit(0)
    }

    let JSONPodspecFile = CommandLine.arguments[1]
    guard let jsonData = NSData(contentsOfFile: JSONPodspecFile) as? Data,
        let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict,
        let podSpec = try? PodSpec(JSONPodspec: JSONPodspec)
    else {
        print("Invalid JSON Podspec")
        exit(1)
    }

    let buildFile = PodBuildFile.with(podSpec: podSpec)
    let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.skylarkConvertibles.flatMap { $0.toSkylark() })
    print(buildFileSkylarkCompiler.run())
}

main()
