Pod::Spec.new do |spec|
  spec.name         = 'Genome'
  spec.version      = '2.1.0'
  spec.license      = 'MIT'
  spec.homepage     = 'https://github.com/LoganWright/Genome'
  spec.authors      = { 'Logan Wright' => 'logan.william.wright@gmail.com' }
  spec.summary      = 'A simple, type safe, failure driven mapping library for serializing json to models in Swift'
  spec.source       = { :git => 'https://github.com/LoganWright/Genome.git', :tag => "#{spec.version}" }
  spec.default_subspec = 'Core'
  spec.ios.deployment_target = "8.0"
  spec.osx.deployment_target = "10.9"
  spec.watchos.deployment_target = "2.0"
  spec.tvos.deployment_target = "9.0"
  spec.requires_arc = true
  spec.social_media_url = 'https://twitter.com/logmaestro'

  spec.subspec 'Core' do |ss|
    ss.source_files = 'Genome/Source/Mapping/**/*.{swift}', 'Genome/Source/Representation/**/*.{swift}', 'Genome/Source/Utility/**/*.{swift}'
  end

  spec.subspec 'Serialization' do |ss|
    ss.source_files = 'Genome/Source/Serialization/*.{swift}'
    ss.dependency 'Genome/Core'
  end

  spec.subspec 'JSON' do |json|
    json.source_files = 'Genome/Source/Serialization/JSON/*.{swift}'
    json.dependency 'Genome/Serialization'
  end

end


