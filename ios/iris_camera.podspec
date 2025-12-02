#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint iris_camera.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'iris_camera'
  s.version          = '0.0.1'
  s.summary          = 'A flexible camera toolkit for Flutter on iOS.'
  s.description      = <<-DESC
  Shared preview surfaces, lens switching, and still capture APIs built on AVFoundation.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
