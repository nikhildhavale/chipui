//
//  ChipInputView.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

public enum ChipImage {
    case remote(URL)
    case local(UIImage)
    case initials(String)
}

public protocol ChipItem {
    var id: String { get }
    var title: String { get }
    var subtitle: String? { get }
    var image: ChipImage? { get }
}

public struct ChipSuggestion: ChipItem {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let image: ChipImage?

    public init(id: String, title: String, subtitle: String? = nil, image: ChipImage? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
}

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
    public var ccButtonTintColor: UIColor?
    public var settingsButtonTintColor: UIColor?
    public var placeholderText: String
    public var emptyResultsText: String
    public var loadingText: String?
    public var matchCountTextProvider: ((Int) -> String?)?
    public var nonRemovableItemIDs: Set<String>
    public var onCcTapped: (() -> Void)?
    public var onSettingsTapped: (() -> Void)?

    public init(
        labelText: String = "To",
        ccIcon: ChipIcon? = nil,
        settingsIcon: ChipIcon? = nil,
        maxHeight: CGFloat? = nil,
        ccButtonTintColor: UIColor? = nil,
        settingsButtonTintColor: UIColor? = nil,
        placeholderText: String = "",
        emptyResultsText: String = "",
        loadingText: String? = nil,
        matchCountTextProvider: ((Int) -> String?)? = nil,
        nonRemovableItemIDs: Set<String> = [],
        onCcTapped: (() -> Void)? = nil,
        onSettingsTapped: (() -> Void)? = nil
    ) {
        self.labelText = labelText
        self.ccIcon = ccIcon
        self.settingsIcon = settingsIcon
        self.maxHeight = maxHeight
        self.ccButtonTintColor = ccButtonTintColor
        self.settingsButtonTintColor = settingsButtonTintColor
        self.placeholderText = placeholderText
        self.emptyResultsText = emptyResultsText
        self.loadingText = loadingText
        self.matchCountTextProvider = matchCountTextProvider
        self.nonRemovableItemIDs = nonRemovableItemIDs
        self.onCcTapped = onCcTapped
        self.onSettingsTapped = onSettingsTapped
    }
}

public final class ChipInputView: UIView {

    public var onHeightChanged: (() -> Void)?
    public var onQueryChanged: ((String) -> Void)?
    public var onSelectionChanged: (([ChipItem]) -> Void)?
    public var onSuggestionsChanged: ((ChipInputView, [ChipItem], Bool) -> Void)?

    public private(set) var selectedItems: [ChipItem] = []

    public var configuration = ChipInputConfiguration() {
        didSet { applyConfiguration() }
    }

    private enum Item {
        case chip(ChipItem)
        case textEntry
    }

    private var suggestions: [ChipItem] = []
    private var localSuggestions: [ChipItem]?
    private var isLoading = false
    private var query = ""
    private var isTextFieldFocused = false
    private var pendingQueryWorkItem: DispatchWorkItem?

    private let fieldContainer = UIView()
    private let fieldLabel = UILabel()
    private let helperLabel = UILabel()
    private let ccButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let trailingButtonsStack = UIStackView()
    private let chipCollectionView = IntrinsicCollectionView(
        frame: .zero,
        collectionViewLayout: ChipInputView.makeChipFlowLayout()
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

    deinit {
        pendingQueryWorkItem?.cancel()
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
        selectedItems.map(Item.chip) + [.textEntry]
    }

    private func configure() {
        clipsToBounds = false
        configureChipField()
        configureLayout()
        applyConfiguration()
        updateHelperText()
    }

    private func applyConfiguration() {
        fieldLabel.text = configuration.labelText
        activeTextField?.placeholder = configuration.placeholderText
        updateHelperText()
        updateChipCollectionHeight()

        let ccTint = configuration.ccButtonTintColor ?? .systemBlue
        ccButton.tintColor = ccTint
        ccButton.setTitleColor(ccTint, for: .normal)

        if let icon = configuration.ccIcon {
            ccButton.setImage(icon.image, for: .normal)
            ccButton.setTitle(icon.title, for: .normal)
            ccButton.isHidden = false
        } else {
            ccButton.setImage(nil, for: .normal)
            ccButton.setTitle(nil, for: .normal)
            ccButton.isHidden = true
        }

        let settingsTint = configuration.settingsButtonTintColor ?? .systemBlue
        settingsButton.tintColor = settingsTint
        settingsButton.setTitleColor(settingsTint, for: .normal)

        let shouldShowSettings = configuration.settingsIcon != nil && !selectedItems.isEmpty
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
        chipCollectionView.register(ChipCell.self, forCellWithReuseIdentifier: ChipCell.reuseIdentifier)
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

    public func updateSuggestions(_ items: [ChipItem]) {
        suggestions = items
        updateHelperText()
        onSuggestionsChanged?(self, suggestions, isLoading)
    }

    public func setLoading(_ loading: Bool) {
        isLoading = loading
        updateHelperText()
        onSuggestionsChanged?(self, suggestions, isLoading)
    }

    public func setLocalSuggestions(_ items: [ChipItem]) {
        localSuggestions = items
        filterLocalSuggestions()
    }

    public func clearLocalSuggestions() {
        localSuggestions = nil
        suggestions = []
        updateHelperText()
    }

    public func toggleSuggestion(_ item: ChipItem) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            removeItem(at: index)
        } else {
            addItem(item, clearQuery: false)
        }
    }

    public func isSelected(_ item: ChipItem) -> Bool {
        isSelected(id: item.id)
    }

    public func isSelected(id: String) -> Bool {
        selectedItems.contains { $0.id == id }
    }

    public func setSelectedItems(_ items: [ChipItem]) {
        selectedItems = items.removingDuplicateChipIDs()
        query = ""
        activeTextField?.text = ""
        chipCollectionView.reloadData()
        updateChipCollectionHeight()
        applyConfiguration()
        onSelectionChanged?(selectedItems)
    }

    private func addItem(_ item: ChipItem, clearQuery: Bool = true) {
        guard !isSelected(id: item.id) else { return }

        selectedItems.append(item)
        if clearQuery {
            query = ""
            activeTextField?.text = ""
        }
        chipCollectionView.reloadData()
        updateChipCollectionHeight()
        applyConfiguration()
        filterLocalSuggestions()
        onSelectionChanged?(selectedItems)

        DispatchQueue.main.async { [weak self] in
            self?.focusTextEntry()
        }
    }

    private func removeItem(at index: Int) {
        guard selectedItems.indices.contains(index) else { return }
        guard !configuration.nonRemovableItemIDs.contains(selectedItems[index].id) else { return }

        selectedItems.remove(at: index)
        chipCollectionView.reloadData()
        updateChipCollectionHeight()
        applyConfiguration()
        filterLocalSuggestions()
        onSelectionChanged?(selectedItems)

        DispatchQueue.main.async { [weak self] in
            self?.focusTextEntry()
        }
    }

    private func focusTextEntry() {
        let textEntryIndexPath = IndexPath(item: selectedItems.count, section: 0)
        chipCollectionView.scrollToItem(at: textEntryIndexPath, at: .bottom, animated: false)
        chipCollectionView.layoutIfNeeded()
        if let cell = chipCollectionView.cellForItem(at: textEntryIndexPath) as? ChipTextEntryCell {
            cell.focus()
        } else {
            activeTextField?.becomeFirstResponder()
        }
    }

    private func textDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        isTextFieldFocused = true
        if query.isEmpty {
            queryDidChange("")
        }
    }

    private func textDidEndEditing() {
        isTextFieldFocused = false
        pendingQueryWorkItem?.cancel()
        pendingQueryWorkItem = nil
    }

    private func queryDidChange(_ text: String) {
        query = text
        filterLocalSuggestions()
        scheduleQueryChanged()
        updateChipCollectionHeight()
    }

    private func scheduleQueryChanged() {
        pendingQueryWorkItem?.cancel()

        guard localSuggestions == nil, isTextFieldFocused else { return }

        let query = query
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isTextFieldFocused else { return }
            self.onQueryChanged?(query)
        }
        pendingQueryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func filterLocalSuggestions() {
        guard let localSuggestions else {
            updateHelperText()
            onSuggestionsChanged?(self, suggestions, isLoading)
            return
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            suggestions = Array(localSuggestions.prefix(12))
        } else {
            suggestions = localSuggestions.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
                ($0.subtitle?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
            }
        }
        updateHelperText()
        onSuggestionsChanged?(self, suggestions, isLoading)
    }

    private func updateHelperText() {
        if isLoading {
            helperLabel.text = configuration.loadingText
            return
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty && suggestions.isEmpty {
            helperLabel.text = configuration.emptyResultsText
        } else {
            helperLabel.text = configuration.matchCountTextProvider?(suggestions.count)
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
    }
}

extension ChipInputView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch items[indexPath.item] {
        case .chip(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChipCell.reuseIdentifier,
                for: indexPath
            ) as! ChipCell

            cell.configure(
                item: item,
                isRemovable: !configuration.nonRemovableItemIDs.contains(item.id)
            ) { [weak self] in
                self?.removeItem(at: indexPath.item)
            }
            return cell

        case .textEntry:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChipTextEntryCell.reuseIdentifier,
                for: indexPath
            ) as! ChipTextEntryCell

            cell.configure(
                text: query,
                placeholder: configuration.placeholderText,
                onTextChanged: { [weak self] textField, text in
                    self?.activeTextField = textField
                    self?.queryDidChange(text)
                },
                onBeginEditing: { [weak self] textField in
                    self?.textDidBeginEditing(textField)
                },
                onEndEditing: { [weak self] in
                    self?.textDidEndEditing()
                },
                onReturn: { [weak self] in
                    self?.acceptCurrentSuggestion()
                },
                onBackspaceWhenEmpty: { [weak self] in
                    guard let self, !self.selectedItems.isEmpty else { return }
                    self.removeItem(at: self.selectedItems.count - 1)
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
        case .chip(let item):
            let font = UIFont.preferredFont(forTextStyle: .body)
            let maxCellWidth = max(collectionView.bounds.width - 24, 1)
            let horizontalPadding: CGFloat = configuration.nonRemovableItemIDs.contains(item.id) ? 58 : 88
            let verticalPadding: CGFloat = 18
            let maxTextWidth = maxCellWidth - horizontalPadding

            let textBounds = (item.title as NSString).boundingRect(
                with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )

            let width = min(maxCellWidth, ceil(textBounds.width + horizontalPadding))
            let height = max(36, ceil(textBounds.height + verticalPadding))
            return CGSize(width: width, height: height)

        case .textEntry:
            let text = query.isEmpty ? configuration.placeholderText : query
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
        guard let item = suggestions.first(where: { !isSelected(id: $0.id) }) else { return }
        addItem(item)
    }
}

private extension Array where Element == ChipItem {

    func removingDuplicateChipIDs() -> [ChipItem] {
        var seen = Set<String>()
        return filter { seen.insert($0.id).inserted }
    }
}
