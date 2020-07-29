Pod::Spec.new do |spec|
  spec.name         = "Parent"
  spec.version      = "0.0.1"
  spec.summary      = "A summary"
  spec.description  = "A description"
  spec.homepage     = "http://p"
  spec.license      = "MIT"
  spec.author             = { "Jerry Marino" => "i@jerrymarino.com" }
  spec.source       = { :git => "http://p/ChildPodspec.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/**/*.{h,m}"
  spec.exclude_files = "Classes/Exclude"
  spec.swift_version = "5"


  spec.subspec "Default" do |ss|
      ss.source_files = "Sources/**/*.swift"
  end

  spec.subspec "Subspec" do |ss|
      #ss.source_files = "Child/**/*.swift"
      ss.source_files = "**/*.swift"
  end

end
