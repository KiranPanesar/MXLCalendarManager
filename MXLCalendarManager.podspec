# -*- coding: utf-8 -*-
#
#  Be sure to run `pod spec lint MXLCalendarManager.podspec' to ensure this is a
Pod::Spec.new do |spec|
  spec.platform = :ios
  spec.name         = 'MXLCalendarManager'
  spec.version      = '0.0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/KiranPanesar/MXLCalendarManager'
  spec.authors      = { 'Kiran Panesar' => 'kiransinghpanesar@gmail.com' }
  spec.summary      = 'A set of classes used to parse and handle iCalendar (.ICS) files'
  spec.source       = { :git => 'https://github.com/KiranPanesar/MXLCalendarManager.git', :tag => '0.0.1' }
  spec.source_files = 'MXLCalendarManager/*.{h,m}'
  spec.frameworks = 'UIKit', 'Foundation'
  spec.requires_arc = true
end
