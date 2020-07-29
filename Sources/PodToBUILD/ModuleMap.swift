public struct ModuleMap: BazelTarget {
    public let name: String // A unique name for this rule.
    public let dirname: String
    public let moduleName: String
    public let headers: [String]
    public let swiftHeader: String?
    public let moduleMapName: String?

    public init(name: String, dirname: String, moduleName: String, headers:
                [String], swiftHeader: String? = nil, moduleMapName: String? = nil) {
        self.name = name + "_module_map_module_map_file"
        self.dirname = dirname
        self.moduleName = moduleName
        self.headers = headers
        self.swiftHeader = swiftHeader
        self.moduleMapName = moduleMapName
    }

    public var acknowledged: Bool {
        return false
    }

    public func toSkylark() -> SkylarkNode {
        var args: [SkylarkFunctionArgument] = [
            .basic(name.toSkylark()),
            .basic(dirname.toSkylark()),
            .basic(moduleName.toSkylark()),
            .basic(headers.toSkylark())
        ]
        if let moduleMapName = self.moduleMapName {
            args.append(.named(name: "module_map_name", value: moduleMapName.toSkylark()))
        }
        args.append(.named(name: "visibility", value: ["//visibility:public"].toSkylark()))
        return SkylarkNode.functionCall(
                name: "gen_module_map",
                arguments: args
         )
    }
}

