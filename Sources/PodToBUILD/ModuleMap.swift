public struct ModuleMap: BazelTarget {
    public let name: String // A unique name for this rule.
    public let moduleName: String
    public let headers: [String]
    public let swiftHeader: String?
    public let moduleMapName: String?

    public init(name: String, moduleName: String, headers:
                [String], swiftHeader: String? = nil, moduleMapName: String? = nil) {
        self.name = name
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
            .named(name: "name", value: name.toSkylark()),
            .named(name: "module_name", value: moduleName.toSkylark()),
            .named(name: "hdrs", value: headers.toSkylark()),
        ]
        if let moduleMapName = self.moduleMapName {
            args.append(.named(name: "module_map_name", value: moduleMapName.toSkylark()))
        }
        if let swiftHeader = self.swiftHeader {
            args.append(.named(name: "swift_header", value: swiftHeader.toSkylark()))
        }
        args.append(.named(name: "visibility", value: ["//visibility:public"].toSkylark()))
        return SkylarkNode.functionCall(
                name: "gen_module_map",
                arguments: args
         )
    }
}

