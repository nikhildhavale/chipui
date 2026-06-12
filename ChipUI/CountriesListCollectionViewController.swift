//
//  CountriesListCollectionViewController.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class CountriesListCollectionViewController: UICollectionViewController {

    var onSuggestionsChanged: ((ChipInputView, [ChipItem], Bool, ChipInputConfiguration) -> Void)?
    var onScroll: (() -> Void)?

    private enum Row: Int, CaseIterable {
        case header
        case recipientChipInput
        case countryChipInput
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?()
    }

    init() {
        super.init(collectionViewLayout: Self.makeLayout())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        collectionView.collectionViewLayout = Self.makeLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .systemBackground
        collectionView.keyboardDismissMode = .interactive
        collectionView.clipsToBounds = false
        collectionView.register(TextListCell.self, forCellWithReuseIdentifier: TextListCell.reuseIdentifier)
        collectionView.register(ChipInputListCell.self, forCellWithReuseIdentifier: ChipInputListCell.reuseIdentifier)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        configuration.backgroundColor = .systemBackground
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let row = Row(rawValue: indexPath.item) else {
            return UICollectionViewCell()
        }

        switch row {
        case .header:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TextListCell.reuseIdentifier,
                for: indexPath
            ) as! TextListCell
            cell.configure(
                title: "Generic Chip Input",
                subtitle: "The first field simulates server-backed recipients. The second field keeps the old country picker data in local-filter mode."
            )
            return cell

        case .recipientChipInput:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChipInputListCell.reuseIdentifier,
                for: indexPath
            ) as! ChipInputListCell
            cell.configureRemoteRecipients(
                onHeightChanged: { [weak collectionView] in
                    collectionView?.collectionViewLayout.invalidateLayout()
                },
                onSuggestionsChanged: { [weak self] inputView, suggestions, loading, configuration in
                    self?.onSuggestionsChanged?(inputView, suggestions, loading, configuration)
                }
            )
            return cell

        case .countryChipInput:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ChipInputListCell.reuseIdentifier,
                for: indexPath
            ) as! ChipInputListCell
            cell.configureLocalCountries(
                onHeightChanged: { [weak collectionView] in
                    collectionView?.collectionViewLayout.invalidateLayout()
                },
                onSuggestionsChanged: { [weak self] inputView, suggestions, loading, configuration in
                    self?.onSuggestionsChanged?(inputView, suggestions, loading, configuration)
                }
            )
            return cell
        }
    }
}

private final class TextListCell: UICollectionViewCell {

    static let reuseIdentifier = "TextListCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func configure() {
        backgroundConfiguration = .listCell()
        layer.zPosition = 0

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 8

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}

private final class ChipInputListCell: UICollectionViewCell {

    static let reuseIdentifier = "ChipInputListCell"

    private static let teamAll = ChipSuggestion(
        id: "team:all",
        title: "All Hands",
        subtitle: "Company-wide team",
        image: .initials("AH")
    )

    private static let recipientSamples: [ChipSuggestion] = [
        ChipSuggestion(id: "user:aditi", title: "Aditi Rao", subtitle: "Product Design", image: .initials("AR")),
        ChipSuggestion(id: "user:ben", title: "Ben Carter", subtitle: "iOS Engineering", image: .initials("BC")),
        ChipSuggestion(id: "user:chen", title: "Chen Wei", subtitle: "Backend Engineering", image: .initials("CW")),
        ChipSuggestion(id: "team:mobile", title: "Mobile Team", subtitle: "12 members", image: .initials("MT")),
        ChipSuggestion(id: "team:support", title: "Customer Support", subtitle: "8 members", image: .initials("CS")),
        ChipSuggestion(id: "user:fatima", title: "Fatima Khan", subtitle: "QA", image: .initials("FK")),
        ChipSuggestion(id: "user:liam", title: "Liam Smith", subtitle: "Sales", image: .initials("LS"))
    ]

    private static let countrySamples: [ChipSuggestion] = Locale.Region.isoRegions
        .compactMap { region -> ChipSuggestion? in
            guard let name = Locale.current.localizedString(forRegionCode: region.identifier) else { return nil }
            return ChipSuggestion(id: region.identifier, title: name, subtitle: region.identifier, image: .initials(String(name.prefix(2))))
        }
        .removingDuplicateChipIDs()
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

    private let chipInputView = ChipInputView()
    private var pendingRemoteSearch: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pendingRemoteSearch?.cancel()
        pendingRemoteSearch = nil
        chipInputView.clearLocalSuggestions()
        chipInputView.onQueryChanged = nil
        chipInputView.onSuggestionsChanged = nil
        chipInputView.onHeightChanged = nil
        chipInputView.setSelectedItems([])
    }

    func configureRemoteRecipients(
        onHeightChanged: @escaping () -> Void,
        onSuggestionsChanged: @escaping (ChipInputView, [ChipItem], Bool, ChipInputConfiguration) -> Void
    ) {
        let configuration = ChipInputConfiguration(
            labelText: "Share with",
            ccIcon: .title("Cc"),
            settingsIcon: .system("slider.horizontal.3"),
            maxHeight: 120,
            placeholderText: "Search colleagues or teams",
            emptyResultsText: "No recipients found.",
            loadingText: "Searching recipients...",
            matchCountTextProvider: { count in count == 0 ? nil : "\(count) recipients" },
            nonRemovableItemIDs: [Self.teamAll.id]
        )

        chipInputView.configuration = configuration
        chipInputView.onHeightChanged = onHeightChanged
        chipInputView.onSuggestionsChanged = { inputView, suggestions, loading in
            onSuggestionsChanged(inputView, suggestions, loading, configuration)
        }
        chipInputView.setSelectedItems([Self.teamAll])

        chipInputView.onQueryChanged = { [weak self, weak chipInputView] query in
            guard let self, let chipInputView else { return }
            self.pendingRemoteSearch?.cancel()
            chipInputView.setLoading(true)

            let workItem = DispatchWorkItem {
                let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
                let matches: [ChipSuggestion]
                if trimmedQuery.isEmpty {
                    matches = Array(Self.recipientSamples.prefix(5))
                } else {
                    matches = Self.recipientSamples.filter {
                        $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
                        ($0.subtitle?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
                    }
                }

                chipInputView.setLoading(false)
                chipInputView.updateSuggestions(matches)
            }
            self.pendingRemoteSearch = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: workItem)
        }
    }

    func configureLocalCountries(
        onHeightChanged: @escaping () -> Void,
        onSuggestionsChanged: @escaping (ChipInputView, [ChipItem], Bool, ChipInputConfiguration) -> Void
    ) {
        let configuration = ChipInputConfiguration(
            labelText: "Country",
            maxHeight: 120,
            placeholderText: "Search countries",
            emptyResultsText: "No matching countries.",
            matchCountTextProvider: { count in count == 0 ? nil : "\(count) matching countries" }
        )

        chipInputView.configuration = configuration
        chipInputView.onHeightChanged = onHeightChanged
        chipInputView.onSuggestionsChanged = { inputView, suggestions, loading in
            onSuggestionsChanged(inputView, suggestions, loading, configuration)
        }
        chipInputView.setSelectedItems([
            ChipSuggestion(id: "IN", title: "India", subtitle: "IN", image: .initials("IN")),
            ChipSuggestion(id: "US", title: "United States", subtitle: "US", image: .initials("US"))
        ])
        chipInputView.setLocalSuggestions(Self.countrySamples)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.zPosition = 100
    }

    private func configure() {
        backgroundConfiguration = .listCell()
        clipsToBounds = false
        layer.zPosition = 10
        contentView.clipsToBounds = false

        contentView.addSubview(chipInputView)
        chipInputView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            chipInputView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            chipInputView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            chipInputView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            chipInputView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}

private extension Array where Element == ChipSuggestion {

    func removingDuplicateChipIDs() -> [ChipSuggestion] {
        var seen = Set<String>()
        return filter { seen.insert($0.id).inserted }
    }
}
