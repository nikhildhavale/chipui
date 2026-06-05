//
//  ViewController.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class ViewController: UIViewController {

    private let listViewController = CountriesListCollectionViewController()
    private let autocompleteTableView = UITableView(frame: .zero, style: .plain)
    private var activeChipInputView: CountryChipInputView?
    private var autocompleteSuggestions: [String] = []
    private var autocompleteTopConstraint: NSLayoutConstraint?
    private var autocompleteLeadingConstraint: NSLayoutConstraint?
    private var autocompleteWidthConstraint: NSLayoutConstraint?
    private var autocompleteHeightConstraint: NSLayoutConstraint?
    private var keyboardTopY: CGFloat = .greatestFiniteMagnitude

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        addListViewController()
        configureAutocompleteOverlay()
        observeKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func addListViewController() {
        listViewController.onAutocompleteChanged = { [weak self] inputView, suggestions in
            self?.showAutocomplete(suggestions, anchoredTo: inputView)
        }

        addChild(listViewController)
        view.addSubview(listViewController.view)
        listViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            listViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            listViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        listViewController.didMove(toParent: self)
    }

    private func configureAutocompleteOverlay() {
        autocompleteTableView.dataSource = self
        autocompleteTableView.delegate = self
        autocompleteTableView.keyboardDismissMode = .onDrag
        autocompleteTableView.layer.cornerRadius = 8
        autocompleteTableView.layer.borderColor = UIColor.separator.cgColor
        autocompleteTableView.layer.borderWidth = 1
        autocompleteTableView.backgroundColor = .systemBackground
        autocompleteTableView.rowHeight = UITableView.automaticDimension
        autocompleteTableView.estimatedRowHeight = 52
        autocompleteTableView.isHidden = true
        autocompleteTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CountryCell")

        view.addSubview(autocompleteTableView)
        autocompleteTableView.translatesAutoresizingMaskIntoConstraints = false

        autocompleteTopConstraint = autocompleteTableView.topAnchor.constraint(equalTo: view.topAnchor)
        autocompleteLeadingConstraint = autocompleteTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        autocompleteWidthConstraint = autocompleteTableView.widthAnchor.constraint(equalToConstant: 1)
        autocompleteHeightConstraint = autocompleteTableView.heightAnchor.constraint(equalToConstant: 1)

        NSLayoutConstraint.activate([
            autocompleteTopConstraint!,
            autocompleteLeadingConstraint!,
            autocompleteWidthConstraint!,
            autocompleteHeightConstraint!
        ])
    }

    private func showAutocomplete(_ suggestions: [String], anchoredTo inputView: CountryChipInputView) {
        activeChipInputView = inputView
        autocompleteSuggestions = suggestions

        let anchorFrame = inputView.autocompleteAnchorFrame(in: view)
        let preferredTop = anchorFrame.maxY + 6
        let keyboardTop = min(keyboardTopY, view.bounds.maxY)
        let availableBelow = keyboardTop - preferredTop - 8
        let desiredHeight = suggestions.isEmpty ? 0 : min(CGFloat(suggestions.count) * 56, 280)
        let overlayHeight = min(desiredHeight, max(0, availableBelow))

        autocompleteTopConstraint?.constant = preferredTop
        autocompleteLeadingConstraint?.constant = anchorFrame.minX
        autocompleteWidthConstraint?.constant = anchorFrame.width
        autocompleteHeightConstraint?.constant = overlayHeight

        autocompleteTableView.reloadData()
        autocompleteTableView.isHidden = suggestions.isEmpty || overlayHeight <= 0
        view.bringSubviewToFront(autocompleteTableView)
    }

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameDidChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardFrameDidChange(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        keyboardTopY = view.convert(keyboardFrame, from: nil).minY
        refreshAutocompletePosition()
    }

    @objc private func keyboardWillHide() {
        keyboardTopY = .greatestFiniteMagnitude
        refreshAutocompletePosition()
    }

    private func refreshAutocompletePosition() {
        guard let activeChipInputView else { return }
        showAutocomplete(autocompleteSuggestions, anchoredTo: activeChipInputView)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        autocompleteSuggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = autocompleteSuggestions[indexPath.row]
        content.textProperties.numberOfLines = 0
        content.secondaryText = "Tap to add country chip"
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .detailDisclosureButton
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        activeChipInputView?.acceptSuggestion(autocompleteSuggestions[indexPath.row])
    }
}
