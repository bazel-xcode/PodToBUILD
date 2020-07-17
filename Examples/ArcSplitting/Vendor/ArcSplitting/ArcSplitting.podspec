Pod::Spec.new do |spec|
  spec.name         = "ArcSplitting"
  spec.version      = "0.0.1"
  spec.summary      = "A summary"
  spec.description  = "A description"
  spec.homepage     = "http://p"
  spec.license      = "MIT"
  spec.author             = { "Jerry Marino" => "i@jerrymarino.com" }
  spec.source       = { :git => "http://p/ArcSplitting.git", :tag => "#{spec.version}" }
  spec.source_files  = "ArcSplitting", "ArcSplitting/**/*.{h,m,mm}"

  mrr_files = [
    'ArcSplitting/NoArc.h',
    'ArcSplitting/NoArc.mm',
  ]

  files = Pathname.glob("ArcSplitting/**/*.{h,m,mm}")
  files = files.map {|file| file.to_path}
  files = files.reject {|file| mrr_files.include?(file)}

  spec.requires_arc = files
  spec.public_header_files = [
    'ArcSplitting/ArcSplitting.h',
  ]

  spec.framework = "Foundation"
  spec.library = 'c++'
end
