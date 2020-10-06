require 'json'

package = JSON.parse(File.read(File.join(__dir__, '../package.json')))

Pod::Spec.new do |s|
  s.name                = "RNReactNativePdfLib"
  s.version             = package['version']
  s.summary             = package['description']
  s.description         = package['description']
  s.homepage            = package['homepage']
  s.license             = package['license']
  s.author              = package['author']
  s.source              = { :git => 'https://github.com/Hopding/react-native-pdf-lib.git', :tag => 'v'+s.version.to_s }

  s.platform              = :ios, '9.0'
  s.ios.deployment_target = '8.0'
  s.dependency 'React'
  s.source_files  = "**/*.{h,mm}"
  s.header_mappings_dir = "lib/include"
  s.ios.vendored_libraries =["lib/universal/libFreeType.a", "lib/universal/libLibJpeg.a", "lib/universal/libLibTiff.a", "lib/universal/libPDFWriter.a", "lib/universal/libZlib.a"]
end