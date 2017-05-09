import Cocoa
import PlaygroundSupport
import PodSpecToBUILD

/*:
 Update the value of `filePathToJSONPodspec` to reference a JSON specification.
 - The build output and podspec will be shown in the assistant view. (View -> Assistant Editor -> Show Assistant Editor)
 - Fields that are unrecognized / unimplemented will be printed to the console.
 */


let podName = "Texture"
let pod = examplePodSpecNamed(name: podName)
let options = BasicBuildOptions(podName: "", userOptions: [String](), globalCopts: [], trace: true)
let jsonPodSpec = try! JSONSerialization.jsonObject(with: try! Data(contentsOf: URL(fileURLWithPath: examplePodSpecFilePath(name: podName)), options: .uncached))

//: Build the PodSpec and run it through the compiler
let buildFile = PodBuildFile.with(podSpec: pod, buildOptions: options)

buildFile.skylarkConvertibles
let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.skylarkConvertibles.toSkylark())
let buildFileOut = buildFileSkylarkCompiler.run()

print("\(buildFileOut)")

//: Assistant View Configuration
let view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 1024 * 10))
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
