//
//  AutocompleteOverlayView.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

public final class AutocompleteOverlayView: UIView {

    public var onToggle: ((ChipItem) -> Void)?
    public var isSelected: ((String) -> Bool)?
    public var emptyResultsText: String?
    public var loadingText: String?

    public var suggestions: [ChipItem] = [] {
        didSet { collectionView.reloadData() }
    }

    public var showsLoading = false {
        didSet { collectionView.reloadData() }
    }

    private enum Row {
        case loading
        case empty
        case suggestion(ChipItem)
    }

    private var rows: [Row] {
        if showsLoading {
            return [.loading]
        }

        if suggestions.isEmpty, emptyResultsText?.isEmpty == false {
            return [.empty]
        }

        return suggestions.map(Row.suggestion)
    }

    private lazy var collectionView: UICollectionView = {
        let layout = Self.makeLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return view
    }()

    private static let suggestionCellReuseIdentifier = "AutocompleteSuggestionCell"
    private static let statusCellReuseIdentifier = "AutocompleteStatusCell"

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private static func makeLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = true
        configuration.backgroundColor = .systemBackground
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    private func configure() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
        clipsToBounds = true

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.backgroundColor = .systemBackground
        collectionView.register(
            AutocompleteSuggestionCell.self,
            forCellWithReuseIdentifier: Self.suggestionCellReuseIdentifier
        )
        collectionView.register(
            AutocompleteStatusCell.self,
            forCellWithReuseIdentifier: Self.statusCellReuseIdentifier
        )

        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension AutocompleteOverlayView: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rows.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch rows[indexPath.item] {
        case .suggestion(let item):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.suggestionCellReuseIdentifier,
                for: indexPath
            ) as! AutocompleteSuggestionCell
            cell.configure(item: item, isSelected: isSelected?(item.id) ?? false)
            return cell

        case .loading:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.statusCellReuseIdentifier,
                for: indexPath
            ) as! AutocompleteStatusCell
            cell.configure(text: loadingText, isLoading: true)
            return cell

        case .empty:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.statusCellReuseIdentifier,
                for: indexPath
            ) as! AutocompleteStatusCell
            cell.configure(text: emptyResultsText, isLoading: false)
            return cell
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .suggestion(let item) = rows[indexPath.item] else { return }
        onToggle?(item)
    }
}

private final class AutocompleteSuggestionCell: UICollectionViewCell {

    private let avatarView = ChipAvatarView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))

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
        avatarView.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        checkmarkImageView.isHidden = true
    }

    func configure(item: ChipItem, isSelected: Bool) {
        avatarView.configure(image: item.image, title: item.title)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty != false
        checkmarkImageView.isHidden = !isSelected
    }

    private func configure() {
        backgroundConfiguration = .listCell()

        avatarView.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontForContentSizeCategory = true

        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.setContentHuggingPriority(.required, for: .horizontal)

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 2

        let stackView = UIStackView(arrangedSubviews: [avatarView, textStackView, checkmarkImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 34),
            avatarView.heightAnchor.constraint(equalToConstant: 34),

            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -4)
        ])
    }
}

private final class AutocompleteStatusCell: UICollectionViewCell {

    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func configure(text: String?, isLoading: Bool) {
        titleLabel.text = text
        titleLabel.isHidden = text?.isEmpty != false
        activityIndicator.isHidden = !isLoading

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func configure() {
        backgroundConfiguration = .listCell()

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [activityIndicator, titleLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8)
        ])
    }
}
