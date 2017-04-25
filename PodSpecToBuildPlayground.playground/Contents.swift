import Cocoa
import PlaygroundSupport
import PodSpecToBUILD

/*:
 Update the value of `filePathToJSONPodspec` to reference a JSON specification.
 - The build output and podspec will be shown in the assistant view. (View -> Assistant Editor -> Show Assistant Editor)
 - Fields that are unrecognized / unimplemented will be printed to the console.
 */
let filePathToJSONPodspec = "/Users/rmalik/dev/iOS/tools/PodSpecToBUILD/Examples/PINCache.podspec.json"

guard let d = try? Data(contentsOf: URL(fileURLWithPath: filePathToJSONPodspec)) else { exit(0) }
guard let jsonPodSpec = (try? JSONSerialization.jsonObject(with: d, options: .allowFragments)) as? JSONDict else { exit(0) }
guard let pod = try? PodSpec(JSONPodspec: jsonPodSpec) else { exit(0) }


//: Build the PodSpec and run it through the compiler
let buildFile = PodBuildFile.with(podSpec: pod)
let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.skylarkConvertibles.flatMap { $0.toSkylark() })
let buildFileOut = buildFileSkylarkCompiler.run()

//: Assistant View Configuration
let view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 1024))
let jsonpodTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: view.frame.width / 2.0, height: view.frame.height))
jsonpodTextView.string = String(data: try JSONSerialization.data(withJSONObject: jsonPodSpec, options: .prettyPrinted), encoding: .utf8)
let buildFileTextView = NSTextView(frame: NSRect(x: view.frame.width / 2.0,
                                                 y: 0,
                                                 width: view.frame.width / 2.0,
                                                 height: view.frame.height))
buildFileTextView.string = buildFileOut
view.addSubview(jsonpodTextView)
view.addSubview(buildFileTextView)
PlaygroundPage.current.liveView = view