Pod::Spec.new do |s|
  s.name         = "tarkit"
  s.version      = "0.1.1"
  s.summary      = "untar and tar files on iOS and OS X. Also supports gzip tars."
  s.homepage     = "https://github.com/daltoniam/tarkit"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Dalton Cherry" => "daltoniam@gmail.com" }
  s.source       = { :git => "https://github.com/daltoniam/tarkit.git", :tag => "#{s.version}" }
  s.social_media_url = 'http://twitter.com/daltoniam'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.source_files = '*.{h,m}'
  s.requires_arc = true
end
