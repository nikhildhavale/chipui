//
//  ChipCells.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class ChipCell: UICollectionViewCell {

    static let reuseIdentifier = "ChipCell"

    private let chipContainer = UIView()
    private let avatarView = ChipAvatarView()
    private let titleLabel = UILabel()
    private let removeButton = UIButton(type: .system)
    private var onRemove: (() -> Void)?

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
        onRemove = nil
    }

    func configure(item: ChipItem, isRemovable: Bool, onRemove: @escaping () -> Void) {
        titleLabel.text = item.title
        avatarView.configure(image: item.image, title: item.title)
        removeButton.isHidden = !isRemovable
        self.onRemove = onRemove
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        chipContainer.backgroundColor = .systemFill
        chipContainer.layer.cornerRadius = 18
        chipContainer.layer.borderColor = UIColor.label.cgColor
        chipContainer.layer.borderWidth = 1

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .label
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        contentView.addSubview(chipContainer)
        chipContainer.addSubview(avatarView)
        chipContainer.addSubview(titleLabel)
        chipContainer.addSubview(removeButton)

        chipContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            chipContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chipContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chipContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            chipContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            avatarView.leadingAnchor.constraint(equalTo: chipContainer.leadingAnchor, constant: 8),
            avatarView.centerYAnchor.constraint(equalTo: chipContainer.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 24),
            avatarView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: chipContainer.topAnchor, constant: 7),
            titleLabel.bottomAnchor.constraint(equalTo: chipContainer.bottomAnchor, constant: -7),

            removeButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            removeButton.trailingAnchor.constraint(equalTo: chipContainer.trailingAnchor, constant: -10),
            removeButton.centerYAnchor.constraint(equalTo: chipContainer.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 24),
            removeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc private func removeTapped() {
        onRemove?()
    }
}

final class ChipTextEntryCell: UICollectionViewCell, UITextFieldDelegate {

    static let reuseIdentifier = "ChipTextEntryCell"

    let textField = BackspaceTextField()

    private var onTextChanged: ((UITextField, String) -> Void)?
    private var onBeginEditing: ((UITextField) -> Void)?
    private var onEndEditing: (() -> Void)?
    private var onReturn: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func configure(
        text: String,
        placeholder: String,
        onTextChanged: @escaping (UITextField, String) -> Void,
        onBeginEditing: @escaping (UITextField) -> Void,
        onEndEditing: @escaping () -> Void,
        onReturn: @escaping () -> Void,
        onBackspaceWhenEmpty: @escaping () -> Void
    ) {
        textField.text = text
        textField.placeholder = placeholder
        textField.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        self.onTextChanged = onTextChanged
        self.onBeginEditing = onBeginEditing
        self.onEndEditing = onEndEditing
        self.onReturn = onReturn
    }

    func focus() {
        textField.becomeFirstResponder()
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        textField.borderStyle = .none
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.inputAccessoryView = makeKeyboardAccessoryToolbar()

        contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @objc private func textDidChange() {
        onTextChanged?(textField, textField.text ?? "")
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?(textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onEndEditing?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return false
    }

    private func makeKeyboardAccessoryToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexibleSpace, doneButton]
        return toolbar
    }

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }
}

final class BackspaceTextField: UITextField {

    var onBackspaceWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        if text?.isEmpty != false {
            onBackspaceWhenEmpty?()
        }

        super.deleteBackward()
    }
}

final class ChipAvatarView: UIView {

    private let imageView = UIImageView()
    private let initialsLabel = UILabel()
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func prepareForReuse() {
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        initialsLabel.text = nil
    }

    func configure(image: ChipImage?, title: String) {
        prepareForReuse()

        switch image {
        case .local(let uiImage):
            setImage(uiImage)
        case .remote(let url):
            setInitials(Self.initials(from: title))
            loadRemoteImage(from: url)
        case .initials(let initials):
            setInitials(initials)
        case .none:
            setInitials(Self.initials(from: title))
        }
    }

    private func configure() {
        backgroundColor = .tertiarySystemFill
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        initialsLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        initialsLabel.textColor = .label
        initialsLabel.textAlignment = .center
        initialsLabel.adjustsFontSizeToFitWidth = true
        initialsLabel.minimumScaleFactor = 0.6

        addSubview(imageView)
        addSubview(initialsLabel)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            initialsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            initialsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            initialsLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            initialsLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func setInitials(_ initials: String) {
        imageView.image = nil
        initialsLabel.text = initials
        initialsLabel.isHidden = false
    }

    private func setImage(_ image: UIImage) {
        imageView.image = image
        initialsLabel.isHidden = true
    }

    private func loadRemoteImage(from url: URL) {
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.setImage(image)
            }
        }
        imageTask?.resume()
    }

    private static func initials(from title: String) -> String {
        let parts = title
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        let initials = String(parts).uppercased()
        return initials.isEmpty ? "?" : initials
    }
}
