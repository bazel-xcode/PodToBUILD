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

  spec.subspec "ChildHeaders" do |ss|
      ss.source_files = "Child/**/*.h"
  end

  spec.subspec "Default" do |ss|
      ss.source_files = "Default.m"
  end
end
