import PodToBUILD

/*
		<dict>
			<key>FooterText</key>
			<string>BSD License
For `IGListKit` software

Copyright (c) 2016, Facebook, Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
</string>
			<key>License</key>
			<string>BSD</string>
			<key>Title</key>
			<string>IGListKit</string>
			<key>Type</key>
			<string>PSGroupSpecifier</string>
		</dict>

*/

/// Read the first LICENSE file at the root of the directory. It doesn't matter
/// what this file is called
private func ReadLicense(file: String?) -> String {
    guard let licensePath = file ?? podGlob(pattern: "*LICENSE*").first else {
        return ""
    }

    let licenseAtPath = try? String(contentsOfFile: licensePath, encoding:
            .utf8)
    return licenseAtPath ?? ""
}

private func dictEntry(withKey key: String, value: String) -> String {
    return  "<key>" + key + "</key>\n" +
            "<string>" + value + "</string>\n"
}

/// Return an entry for Acknowledgements.plist
public func AcknowledgmentEntry(forPodspec podSpec: PodSpec) -> [String: String] {
    let license = podSpec.license
    // If the license hasn't provided a text, read it in
    let text = license.text ?? ReadLicense(file: license.file)
    let type = license.type ?? ""
    return [
        "FooterText" : text,
        "License" : type,
        "Title" : podSpec.name,
        "Type" : "PSGroupSpecifier"
    ]
}

public func RenderAcknowledgmentEntry(entry: [String: String]) -> String {
    var result = "<dict>\n"
    for (key, value) in entry {
        result += dictEntry(withKey: key, value: value)
    }
    result += "</dict>"
    return result
}


