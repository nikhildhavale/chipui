//
//  ViewController.swift
//  ChipUI
//
//  Created by Nikhil Dhavale on 26/05/26.
//

import UIKit

final class ViewController: UIViewController {

    private let listViewController = CountriesListCollectionViewController()
    private let autocompleteOverlay = AutocompleteOverlayView()
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
        listViewController.onScroll = { [weak self] in
            self?.positionAutocomplete()
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
        autocompleteOverlay.isHidden = true
        autocompleteOverlay.onToggle = { [weak self] value in
            self?.activeChipInputView?.toggleSuggestion(value)
        }
        autocompleteOverlay.isSelected = { [weak self] value in
            self?.activeChipInputView?.isSelected(value) ?? false
        }

        view.addSubview(autocompleteOverlay)
        autocompleteOverlay.translatesAutoresizingMaskIntoConstraints = false

        autocompleteTopConstraint = autocompleteOverlay.topAnchor.constraint(equalTo: view.topAnchor)
        autocompleteLeadingConstraint = autocompleteOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        autocompleteWidthConstraint = autocompleteOverlay.widthAnchor.constraint(equalToConstant: 1)
        autocompleteHeightConstraint = autocompleteOverlay.heightAnchor.constraint(equalToConstant: 1)

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

        DispatchQueue.main.async { [weak self] in
            self?.positionAutocomplete()
        }
    }

    private func positionAutocomplete() {
        guard let inputView = activeChipInputView else { return }
        let suggestions = autocompleteSuggestions

        view.layoutIfNeeded()

        let anchorFrame = inputView.autocompleteAnchorFrame(in: view)
        let preferredTop = anchorFrame.maxY + 6
        let keyboardTop = min(keyboardTopY, view.bounds.maxY)
        let availableBelow = keyboardTop - preferredTop - 8
        let overlayHeight = suggestions.isEmpty ? 0 : max(0, availableBelow)

        autocompleteTopConstraint?.constant = preferredTop
        autocompleteLeadingConstraint?.constant = anchorFrame.minX
        autocompleteWidthConstraint?.constant = anchorFrame.width
        autocompleteHeightConstraint?.constant = overlayHeight

        autocompleteOverlay.suggestions = suggestions
        autocompleteOverlay.isHidden = suggestions.isEmpty || overlayHeight <= 0
        view.bringSubviewToFront(autocompleteOverlay)
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

