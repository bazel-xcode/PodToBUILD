import PodToBUILD

/*
 Example Acknowlegments Plist output (IGListKit)
 <dict>
 <key>Title</key>
 <string>IGListKit</string>
 <key>Type</key>
 <string>PSGroupSpecifier</string>
 <key>License</key>
 <string>BSD</string>
 <key>FooterText</key>
 <string>BSD License
 For `IGListKit` software

 Copyright (c) 2016, Facebook, Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 </string>
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
public func AcknowledgmentEntry(forPodspec podSpec: PodSpec) -> [(String, String)] {
    let license = podSpec.license
    // If the license hasn't provided a text, read it in
    let text = license.text ?? ReadLicense(file: license.file)
    let type = license.type ?? ""
    return [
        ("Title", podSpec.name),
        ("Type", "PSGroupSpecifier"),
        ("License", type),
        ("FooterText", text)
    ]
}

fileprivate func escapeXMLEntities(for str: String) -> String {
    /*
     Escaping[edit]
     XML provides escape facilities for including characters that are problematic to include directly. For example:

     The characters "<" and "&" are key syntax markers and may never appear in content outside a CDATA section. It is allowed, but not recommended, to use "<" in XML entity values.[13]
     Some character encodings support only a subset of Unicode. For example, it is legal to encode an XML document in ASCII, but ASCII lacks code points for Unicode characters such as "é".
     It might not be possible to type the character on the author's machine.
     Some characters have glyphs that cannot be visually distinguished from other characters, such as the non-breaking space (&#xa0;) " " and the space (&#x20;) " ", and the Cyrillic capital letter A (&#x410;) "А" and the Latin capital letter A (&#x41;) "A".
     There are five predefined entities:

     &lt; represents "<";
     &gt; represents ">";
     &amp; represents "&";
     &apos; represents "'";
     &quot; represents '"'.
     All permitted Unicode characters may be represented with a numeric character reference. Consider the Chinese character "中", whose numeric code in Unicode is hexadecimal 4E2D, or decimal 20,013. A user whose keyboard offers no method for entering this character could still insert it in an XML document encoded either as &#20013; or &#x4e2d;. Similarly, the string "I <3 Jörg" could be encoded for inclusion in an XML document as I &lt;3 J&#xF6;rg.

     &#0; is not permitted, however, because the null character is one of the control characters excluded from XML, even when using a numeric character reference.[14] An alternative encoding mechanism such as Base64 is needed to represent such characters.
     */
    return str.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "'", with: "&apos;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "&#0;", with: "")
}

public func RenderAcknowledgmentEntry(entry: [(String, String)]) -> String {
    var result = "<dict>\n"
    for (key, value) in entry {
        result += dictEntry(withKey: key, value: escapeXMLEntities(for: value))
    }
    result += "</dict>"
    return result
}
