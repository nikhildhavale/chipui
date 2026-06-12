//
//  CountryChipInputView.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

public enum ChipIcon {
    case system(String)
    case fontAwesome(String)
    case title(String)

    var image: UIImage? {
        switch self {
        case .system(let name):
            return UIImage(systemName: name)
        case .fontAwesome, .title:
            return nil
        }
    }

    var title: String? {
        switch self {
        case .title(let text):
            return text
        case .system, .fontAwesome:
            return nil
        }
    }
}

public struct ChipInputConfiguration {
    public var labelText: String
    public var ccIcon: ChipIcon?
    public var settingsIcon: ChipIcon?
    public var maxHeight: CGFloat?
    public var onCcTapped: (() -> Void)?
    public var onSettingsTapped: (() -> Void)?

    public init(
        labelText: String = "To",
        ccIcon: ChipIcon? = nil,
        settingsIcon: ChipIcon? = nil,
        maxHeight: CGFloat? = nil,
        onCcTapped: (() -> Void)? = nil,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.labelText = labelText
        self.ccIcon = ccIcon
        self.settingsIcon = settingsIcon
        self.maxHeight = maxHeight
        self.onCcTapped = onCcTapped
        self.onSettingsTapped = onSettingsTapped
    }
}

public final class CountryChipInputView: UIView {

    public var onHeightChanged: (() -> Void)?
    public var onAutocompleteChanged: ((CountryChipInputView, [String]) -> Void)?

    public var configuration = ChipInputConfiguration() {
        didSet { applyConfiguration() }
    }

    private enum Item {
        case chip(String)
        case textEntry
    }

    private let countries = Locale.Region.isoRegions
        .compactMap { Locale.current.localizedString(forRegionCode: $0.identifier) }
        .removingDuplicates()
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    private var selectedCountries = ["India", "United States"]
    private var filteredCountries: [String] = []
    private var query = ""

    private let fieldContainer = UIView()
    private let fieldLabel = UILabel()
    private let helperLabel = UILabel()
    private let ccButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let trailingButtonsStack = UIStackView()
    private let chipCollectionView = IntrinsicCollectionView(
        frame: .zero,
        collectionViewLayout: CountryChipInputView.makeChipFlowLayout()
    )

    private weak var activeTextField: UITextField?
    private var chipCollectionHeightConstraint: NSLayoutConstraint?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateChipCollectionHeight()
    }

    private static func makeChipFlowLayout() -> UICollectionViewLayout {
        let layout = LeadingAlignedFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        return layout
    }

    private var items: [Item] {
        selectedCountries.map(Item.chip) + [.textEntry]
    }

    private func configure() {
        clipsToBounds = false
        configureChipField()
        configureLayout()
        applyConfiguration()
        updateAutocomplete()
    }

    private func applyConfiguration() {
        fieldLabel.text = configuration.labelText
        updateChipCollectionHeight()

        if let icon = configuration.ccIcon {
            ccButton.setImage(icon.image, for: .normal)
            ccButton.setTitle(icon.title, for: .normal)
            ccButton.isHidden = false
        } else {
            ccButton.setImage(nil, for: .normal)
            ccButton.setTitle(nil, for: .normal)
            ccButton.isHidden = true
        }

        let shouldShowSettings = configuration.settingsIcon != nil && !selectedCountries.isEmpty
        if shouldShowSettings, let icon = configuration.settingsIcon {
            settingsButton.setImage(icon.image, for: .normal)
            settingsButton.setTitle(icon.title, for: .normal)
            settingsButton.isHidden = false
        } else {
            settingsButton.setImage(nil, for: .normal)
            settingsButton.setTitle(nil, for: .normal)
            settingsButton.isHidden = true
        }
    }

    @objc private func ccButtonTapped() {
        configuration.onCcTapped?()
    }

    @objc private func settingsButtonTapped() {
        configuration.onSettingsTapped?()
    }

    private func configureChipField() {
        fieldContainer.backgroundColor = .secondarySystemBackground
        fieldContainer.layer.cornerRadius = 8
        fieldContainer.layer.borderWidth = 1
        fieldContainer.layer.borderColor = UIColor.systemBlue.cgColor

        fieldLabel.font = .systemFont(ofSize: 17)
        fieldLabel.textColor = .label
        fieldLabel.adjustsFontForContentSizeCategory = true
        fieldLabel.setContentHuggingPriority(.required, for: .horizontal)
        fieldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        ccButton.tintColor = .systemBlue
        ccButton.setContentHuggingPriority(.required, for: .horizontal)
        ccButton.addTarget(self, action: #selector(ccButtonTapped), for: .touchUpInside)

        settingsButton.tintColor = .systemBlue
        settingsButton.setContentHuggingPriority(.required, for: .horizontal)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)

        trailingButtonsStack.axis = .horizontal
        trailingButtonsStack.spacing = 12
        trailingButtonsStack.alignment = .center
        trailingButtonsStack.addArrangedSubview(ccButton)
        trailingButtonsStack.addArrangedSubview(settingsButton)
        trailingButtonsStack.setContentHuggingPriority(.required, for: .horizontal)
        trailingButtonsStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        helperLabel.font = .preferredFont(forTextStyle: .caption1)
        helperLabel.textColor = .secondaryLabel
        helperLabel.numberOfLines = 0
        helperLabel.adjustsFontForContentSizeCategory = true

        chipCollectionView.backgroundColor = .clear
        chipCollectionView.dataSource = self
        chipCollectionView.delegate = self
        chipCollectionView.keyboardDismissMode = .none
        chipCollectionView.semanticContentAttribute = .forceLeftToRight
        chipCollectionView.contentInsetAdjustmentBehavior = .never
        chipCollectionView.register(CountryChipCell.self, forCellWithReuseIdentifier: CountryChipCell.reuseIdentifier)
        chipCollectionView.register(ChipTextEntryCell.self, forCellWithReuseIdentifier: ChipTextEntryCell.reuseIdentifier)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleFieldTap))
        tapGesture.cancelsTouchesInView = false
        fieldContainer.addGestureRecognizer(tapGesture)
    }

    @objc private func handleFieldTap() {
        focusTextEntry()
    }

    private func configureLayout() {
        addSubview(fieldContainer)
        addSubview(helperLabel)
        fieldContainer.addSubview(fieldLabel)
        fieldContainer.addSubview(trailingButtonsStack)
        fieldContainer.addSubview(chipCollectionView)

        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        fieldLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        chipCollectionView.translatesAutoresizingMaskIntoConstraints = false

        chipCollectionHeightConstraint = chipCollectionView.heightAnchor.constraint(equalToConstant: 52)

        NSLayoutConstraint.activate([
            fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            fieldContainer.topAnchor.constraint(equalTo: topAnchor),

            fieldLabel.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 12),
            fieldLabel.centerYAnchor.constraint(equalTo: chipCollectionView.topAnchor, constant: 28),

            trailingButtonsStack.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -12),
            trailingButtonsStack.centerYAnchor.constraint(equalTo: chipCollectionView.topAnchor, constant: 28),

            chipCollectionView.leadingAnchor.constraint(equalTo: fieldLabel.trailingAnchor, constant: 8),
            chipCollectionView.trailingAnchor.constraint(equalTo: trailingButtonsStack.leadingAnchor, constant: -8),
            chipCollectionView.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            chipCollectionView.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),

            helperLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            helperLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            helperLabel.topAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: 6),
            helperLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            chipCollectionHeightConstraint!
        ])
    }

    public func autocompleteAnchorFrame(in view: UIView) -> CGRect {
        fieldContainer.convert(fieldContainer.bounds, to: view)
    }

    public func toggleSuggestion(_ country: String) {
        if let index = selectedCountries.firstIndex(of: country) {
            removeCountry(at: index)
        } else {
            addCountry(country, clearQuery: false)
        }
    }

    public func isSelected(_ country: String) -> Bool {
        selectedCountries.contains(country)
    }

    private func updateAutocomplete() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedQuery.isEmpty {
            filteredCountries = Array(countries.prefix(12))
            helperLabel.text = ""
        } else {
            filteredCountries = countries.filter {
                $0.localizedCaseInsensitiveContains(trimmedQuery)
            }
            helperLabel.text = filteredCountries.isEmpty ? "No matching countries." : "\(filteredCountries.count) matching countries"
        }

        onAutocompleteChanged?(self, filteredCountries)
    }

    private func addCountry(_ country: String, clearQuery: Bool = true) {
        guard !selectedCountries.contains(country) else { return }

        selectedCountries.append(country)
        if clearQuery {
            query = ""
            activeTextField?.text = ""
        }
        chipCollectionView.reloadData()
        updateChipCollectionHeight()
        updateAutocomplete()
        applyConfiguration()

        DispatchQueue.main.async { [weak self] in
            self?.focusTextEntry()
        }
    }

    private func removeCountry(at index: Int) {
        guard selectedCountries.indices.contains(index) else { return }

        selectedCountries.remove(at: index)
        chipCollectionView.reloadData()
        updateChipCollectionHeight()
        updateAutocomplete()
        applyConfiguration()

        DispatchQueue.main.async { [weak self] in
            self?.focusTextEntry()
        }
    }

    private func focusTextEntry() {
        let textEntryIndexPath = IndexPath(item: selectedCountries.count, section: 0)
        chipCollectionView.scrollToItem(at: textEntryIndexPath, at: .bottom, animated: false)
        chipCollectionView.layoutIfNeeded()
        if let cell = chipCollectionView.cellForItem(at: textEntryIndexPath) as? ChipTextEntryCell {
            cell.focus()
        } else {
            activeTextField?.becomeFirstResponder()
        }
    }

    private func updateChipCollectionHeight() {
        chipCollectionView.collectionViewLayout.invalidateLayout()
        chipCollectionView.layoutIfNeeded()

        let contentHeight = chipCollectionView.collectionViewLayout.collectionViewContentSize.height
        var nextHeight = max(52, contentHeight)
        if let maxHeight = configuration.maxHeight {
            nextHeight = min(nextHeight, max(52, maxHeight))
        }

        let shouldScroll = contentHeight > nextHeight + 0.5
        chipCollectionView.isScrollEnabled = shouldScroll
        chipCollectionView.showsVerticalScrollIndicator = shouldScroll

        guard chipCollectionHeightConstraint?.constant != nextHeight else { return }

        chipCollectionHeightConstraint?.constant = nextHeight
        invalidateIntrinsicContentSize()
        onHeightChanged?()
        onAutocompleteChanged?(self, filteredCountries)
    }
}

extension CountryChipInputView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch items[indexPath.item] {
        case .chip(let country):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CountryChipCell.reuseIdentifier,
                for: indexPath
            ) as! CountryChipCell

            cell.configure(title: country) { [weak self] in
                self?.removeCountry(at: indexPath.item)
            }
            return cell

        case .textEntry:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChipTextEntryCell.reuseIdentifier,
                for: indexPath
            ) as! ChipTextEntryCell

            cell.configure(
                text: query,
                onTextChanged: { [weak self] textField, text in
                    self?.activeTextField = textField
                    self?.query = text
                    self?.updateAutocomplete()
                    self?.updateChipCollectionHeight()
                },
                onReturn: { [weak self] in
                    self?.acceptCurrentSuggestion()
                },
                onBackspaceWhenEmpty: { [weak self] in
                    guard let self, !self.selectedCountries.isEmpty else { return }
                    self.removeCountry(at: self.selectedCountries.count - 1)
                }
            )
            activeTextField = cell.textField
            return cell
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        switch items[indexPath.item] {
        case .chip(let country):
            let font = UIFont.preferredFont(forTextStyle: .body)
            let maxCellWidth = max(collectionView.bounds.width - 24, 1)
            let horizontalPadding: CGFloat = 58
            let verticalPadding: CGFloat = 18
            let maxTextWidth = maxCellWidth - horizontalPadding

            let textBounds = (country as NSString).boundingRect(
                with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )

            let width = min(maxCellWidth, ceil(textBounds.width + horizontalPadding))
            let height = max(36, ceil(textBounds.height + verticalPadding))
            return CGSize(width: width, height: height)

        case .textEntry:
            let text = query.isEmpty ? "Search countries" : query
            let font = UIFont.preferredFont(forTextStyle: .body)
            let maxCellWidth = max(collectionView.bounds.width - 24, 120)
            let textWidth = (text as NSString).size(withAttributes: [.font: font]).width + 28
            return CGSize(width: min(max(140, ceil(textWidth)), maxCellWidth), height: 40)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if case .textEntry = items[indexPath.item] {
            focusTextEntry()
        }
    }

    private func acceptCurrentSuggestion() {
        guard let country = filteredCountries.first(where: { !selectedCountries.contains($0) }) else { return }
        addCountry(country)
    }
}
