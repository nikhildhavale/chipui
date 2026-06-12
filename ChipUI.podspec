Pod::Spec.new do |s|
  s.name             = 'ChipUI'
  s.version          = '0.1.0'
  s.summary          = 'A configurable UIKit chip input view with autocomplete.'

  s.description      = <<-DESC
    ChipUI provides a reusable UIKit component for chip-style input with
    autocomplete support, a configurable leading label, and trailing action
    buttons (Cc / settings) that can be driven by SF Symbols, plain text
    titles, or FontAwesome glyphs (FontAwesome support is reserved via the
    ChipIcon enum but not yet implemented).
  DESC

  s.homepage         = 'https://github.com/nikhilvd/ChipUI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nikhil Dhavale' => 'nikhil_dhavale@hotmail.com' }
  s.source           = { :git => 'https://github.com/nikhilvd/ChipUI.git', :tag => s.version.to_s }

  s.ios.deployment_target = '16.0'
  s.swift_versions        = ['5.9']
  s.frameworks            = 'UIKit'

  s.source_files = [
    'ChipUI/CountryChipInputView.swift',
    'ChipUI/CountryChipCells.swift',
    'ChipUI/CollectionViewHelpers.swift',
    'ChipUI/AutocompleteOverlayView.swift'
  ]

  s.exclude_files = ['Package.swift']
end
