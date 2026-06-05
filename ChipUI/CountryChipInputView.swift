//
//  CountryChipInputView.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class CountryChipInputView: UIView {

    var onHeightChanged: (() -> Void)?
    var onAutocompleteChanged: ((CountryChipInputView, [String]) -> Void)?

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
    private let chipCollectionView = IntrinsicCollectionView(
        frame: .zero,
        collectionViewLayout: CountryChipInputView.makeChipFlowLayout()
    )

    private weak var activeTextField: UITextField?
    private var chipCollectionHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layoutSubviews() {
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
        updateAutocomplete()
    }

    private func configureChipField() {
        fieldContainer.backgroundColor = .secondarySystemBackground
        fieldContainer.layer.cornerRadius = 8
        fieldContainer.layer.borderWidth = 1
        fieldContainer.layer.borderColor = UIColor.systemBlue.cgColor

        fieldLabel.text = "Countries"
        fieldLabel.font = .preferredFont(forTextStyle: .caption1)
        fieldLabel.textColor = .systemBlue
        fieldLabel.adjustsFontForContentSizeCategory = true

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
    }

    private func configureLayout() {
        addSubview(fieldContainer)
        addSubview(helperLabel)
        fieldContainer.addSubview(fieldLabel)
        fieldContainer.addSubview(chipCollectionView)

        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        fieldLabel.translatesAutoresizingMaskIntoConstraints = false
        chipCollectionView.translatesAutoresizingMaskIntoConstraints = false

        chipCollectionHeightConstraint = chipCollectionView.heightAnchor.constraint(equalToConstant: 52)

        NSLayoutConstraint.activate([
            fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            fieldContainer.topAnchor.constraint(equalTo: topAnchor),

            fieldLabel.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 12),
            fieldLabel.trailingAnchor.constraint(lessThanOrEqualTo: fieldContainer.trailingAnchor, constant: -12),
            fieldLabel.topAnchor.constraint(equalTo: fieldContainer.topAnchor, constant: 8),

            chipCollectionView.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            chipCollectionView.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            chipCollectionView.topAnchor.constraint(equalTo: fieldLabel.bottomAnchor, constant: 2),
            chipCollectionView.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),

            helperLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            helperLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            helperLabel.topAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: 6),
            helperLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            chipCollectionHeightConstraint!
        ])
    }

    func autocompleteAnchorFrame(in view: UIView) -> CGRect {
        fieldContainer.convert(fieldContainer.bounds, to: view)
    }

    func toggleSuggestion(_ country: String) {
        if let index = selectedCountries.firstIndex(of: country) {
            removeCountry(at: index)
        } else {
            addCountry(country, clearQuery: false)
        }
    }

    func isSelected(_ country: String) -> Bool {
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

        DispatchQueue.main.async { [weak self] in
            self?.focusTextEntry()
        }
    }

    private func focusTextEntry() {
        let textEntryIndexPath = IndexPath(item: selectedCountries.count, section: 0)
        chipCollectionView.scrollToItem(at: textEntryIndexPath, at: .bottom, animated: false)
        let cell = chipCollectionView.cellForItem(at: textEntryIndexPath) as? ChipTextEntryCell
        cell?.focus()
    }

    private func updateChipCollectionHeight() {
        chipCollectionView.collectionViewLayout.invalidateLayout()
        chipCollectionView.layoutIfNeeded()

        let contentHeight = chipCollectionView.collectionViewLayout.collectionViewContentSize.height
        let nextHeight = max(52, contentHeight)
        guard chipCollectionHeightConstraint?.constant != nextHeight else { return }

        chipCollectionHeightConstraint?.constant = nextHeight
        invalidateIntrinsicContentSize()
        onHeightChanged?()
        onAutocompleteChanged?(self, filteredCountries)
    }
}

extension CountryChipInputView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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

    func collectionView(
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if case .textEntry = items[indexPath.item] {
            focusTextEntry()
        }
    }

    private func acceptCurrentSuggestion() {
        guard let country = filteredCountries.first(where: { !selectedCountries.contains($0) }) else { return }
        addCountry(country)
    }
}
