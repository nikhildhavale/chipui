//
//  CountriesListCollectionViewController.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class CountriesListCollectionViewController: UICollectionViewController {

    var onAutocompleteChanged: ((CountryChipInputView, [String]) -> Void)?

    private enum Row: Int, CaseIterable {
        case header
        case countryChipInput
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
        collectionView.register(CountryChipInputListCell.self, forCellWithReuseIdentifier: CountryChipInputListCell.reuseIdentifier)
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
                title: "MDC-Style Country Chips",
                subtitle: "This screen is a child UICollectionViewController list. The country chip autocomplete input is one list cell."
            )
            return cell

        case .countryChipInput:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CountryChipInputListCell.reuseIdentifier,
                for: indexPath
            ) as! CountryChipInputListCell
            cell.configure(
                onHeightChanged: { [weak collectionView] in
                    collectionView?.collectionViewLayout.invalidateLayout()
                },
                onAutocompleteChanged: { [weak self] inputView, suggestions in
                    self?.onAutocompleteChanged?(inputView, suggestions)
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

private final class CountryChipInputListCell: UICollectionViewCell {

    static let reuseIdentifier = "CountryChipInputListCell"

    private let chipInputView = CountryChipInputView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func configure(
        onHeightChanged: @escaping () -> Void,
        onAutocompleteChanged: @escaping (CountryChipInputView, [String]) -> Void
    ) {
        chipInputView.onHeightChanged = onHeightChanged
        chipInputView.onAutocompleteChanged = onAutocompleteChanged
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
