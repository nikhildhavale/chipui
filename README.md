# ChipUI

ChipUI is a reusable UIKit component for chip-style input with autocomplete, a configurable leading label, and optional trailing action buttons.

## Requirements

- iOS 16.0+
- Swift 5.9+
- UIKit

## Installation

### Swift Package Manager

In Xcode:

1. Open your project.
2. Go to **File > Add Packages...**
3. Enter the repository URL:
   ```text
   https://github.com/nikhildhavale/chipui.git
   ```
4. Choose the version rule you want and add the `ChipUI` library target to your app target.

Then import it where needed:

```swift
import ChipUI
```

### CocoaPods

Add this to your `Podfile`:

```ruby
platform :ios, '16.0'
use_frameworks!

target 'YourAppTarget' do
  pod 'ChipUI', :git => 'https://github.com/nikhildhavale/chipui.git', :branch => 'main'
end
```

Run:

```bash
pod install
```

Then import it in your source file:

```swift
import ChipUI
```

## What it provides

- `CountryChipInputView`: the main chip input view.
- `ChipInputConfiguration`: configures the label and trailing buttons.
- `ChipIcon`: lets you use an SF Symbol or plain text for the trailing actions.

## Basic usage

```swift
import UIKit
import ChipUI

final class ComposeViewController: UIViewController {
    private let chipInputView = CountryChipInputView()
    private let suggestionsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        chipInputView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        suggestionsLabel.numberOfLines = 0

        chipInputView.configuration = ChipInputConfiguration(
            labelText: "To",
            ccIcon: .title("Cc"),
            settingsIcon: .system("slider.horizontal.3"),
            onCcTapped: {
                print("Cc tapped")
            },
            onSettingsTapped: {
                print("Settings tapped")
            }
        )

        chipInputView.onAutocompleteChanged = { [weak self] _, suggestions in
            self?.suggestionsLabel.text = suggestions.prefix(5).joined(separator: ", ")
        }

        chipInputView.onHeightChanged = { [weak self] in
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        }

        view.addSubview(chipInputView)
        view.addSubview(suggestionsLabel)

        NSLayoutConstraint.activate([
            chipInputView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            chipInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chipInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            suggestionsLabel.topAnchor.constraint(equalTo: chipInputView.bottomAnchor, constant: 16),
            suggestionsLabel.leadingAnchor.constraint(equalTo: chipInputView.leadingAnchor),
            suggestionsLabel.trailingAnchor.constraint(equalTo: chipInputView.trailingAnchor)
        ])
    }
}
```

## Configuration

`ChipInputConfiguration` supports:

- `labelText`: leading field label, defaults to `"To"`.
- `ccIcon`: optional trailing action for a Cc-style button.
- `settingsIcon`: optional trailing action button; it is shown only when at least one chip is selected.
- `onCcTapped`: callback when the Cc button is tapped.
- `onSettingsTapped`: callback when the settings button is tapped.

`ChipIcon` supports:

- `.system("symbol.name")` for SF Symbols.
- `.title("Text")` for a text button.
- `.fontAwesome("...")` is present in the API but not implemented yet.

## Autocomplete integration

`CountryChipInputView` computes suggestions internally and reports them through `onAutocompleteChanged`.
That makes it easy to present your own suggestion UI such as a table view, popover, or bottom sheet.

Useful APIs:

- `onAutocompleteChanged`: provides the current filtered suggestions.
- `toggleSuggestion(_:)`: adds or removes a suggested value.
- `autocompleteAnchorFrame(in:)`: returns the frame of the input area in another view's coordinate space for anchoring a popover.

Example:

```swift
chipInputView.onAutocompleteChanged = { [weak self] inputView, suggestions in
    guard let self else { return }

    let anchor = inputView.autocompleteAnchorFrame(in: self.view)
    print("Show suggestions near:", anchor)
    print("Suggestions:", suggestions)
}

chipInputView.toggleSuggestion("Canada")
```

## Notes

- The package currently ships the UIKit chip input view source files only.
- The sample app files in the Xcode project are excluded from Swift Package Manager.
- The default dataset is based on localized `Locale.Region.isoRegions` names.

## License

MIT
