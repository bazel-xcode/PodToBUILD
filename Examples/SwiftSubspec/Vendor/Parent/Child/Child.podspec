Pod::Spec.new do |spec|
  spec.name         = "Child"
  spec.version      = "0.0.1"
  spec.summary      = "A summary"
  spec.description  = "A description"
  spec.homepage     = "http://p"
  spec.license      = "MIT"
  spec.author             = { "Jerry Marino" => "i@jerrymarino.com" }
  spec.source       = { :git => "http://p/ChildPodspec.git", :tag => "#{spec.version}" }

  # Note: this doesn't include headers. We have a glob pattern that over-reaches
  # into this subspec
  spec.source_files  = "Sources/**/*.m"
  spec.exclude_files = "Classes/Exclude"
  spec.dependency "Parent/ChildHeaders"
  spec.subspec "Default" do |ss|
  end
end
