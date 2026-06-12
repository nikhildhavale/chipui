//
//  CountryChipCells.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class CountryChipCell: UICollectionViewCell {

    static let reuseIdentifier = "CountryChipCell"

    private let chipContainer = UIView()
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

    func configure(title: String, onRemove: @escaping () -> Void) {
        titleLabel.text = title
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
        chipContainer.addSubview(titleLabel)
        chipContainer.addSubview(removeButton)

        chipContainer.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            chipContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chipContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chipContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            chipContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: chipContainer.leadingAnchor, constant: 14),
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
        onTextChanged: @escaping (UITextField, String) -> Void,
        onReturn: @escaping () -> Void,
        onBackspaceWhenEmpty: @escaping () -> Void
    ) {
        textField.text = text
        textField.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        self.onTextChanged = onTextChanged
        self.onReturn = onReturn
    }

    func focus() {
        textField.becomeFirstResponder()
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        textField.placeholder = "Search countries"
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
