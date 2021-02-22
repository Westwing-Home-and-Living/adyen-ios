//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import PassKit
import UIKit

internal protocol VoucherViewDelegate: AnyObject {

    func saveToAppleWallet(voucherAction: GenericVoucherAction, presentingViewController: UIViewController, completion: (() -> Void)?)

    func didComplete(voucherAction: GenericVoucherAction, presentingViewController: UIViewController)

    func saveAsImage(voucherView: UIView, presentingViewController: UIViewController)
}

internal class AbstractVoucherView: UIView, Localizable {

    internal weak var delegate: VoucherViewDelegate?

    internal struct Model {

        internal let voucherAction: GenericVoucherAction

        internal let separatorModel: VoucherSeparatorView.Model

        internal let saveButtonTitle: String

        internal let doneButtonTitle: String

        internal let style: Style

        internal struct Style {

            internal let mainButtonStyle: ButtonStyle

            internal let secondaryButtonStyle: ButtonStyle

            internal let backgroundColor: UIColor
        }
    }

    internal var localizationParameters: LocalizationParameters?

    internal weak var presenter: UIViewController?

    private lazy var apiClient: APIClient = {
        var environment = Environment(baseURL: URL(string: "http://localhost:8080/"))
        environment.clientKey = "devl_F73CCZ4Y7NHFRLC3OMVZHDIVQY47VWFL"
        return APIClient(environment: environment)
    }()

    /// Ugly hack to work around the following bug
    /// https://stackoverflow.com/questions/59413850/uiactivityviewcontroller-dismissing-current-view-controller-after-sharing-file
    private lazy var fakeViewController: UIViewController = {
        let viewController = UIViewController()
        presenter?.addChild(viewController)
        presenter?.view.insertSubview(viewController.view, at: 0)
        viewController.view.frame = .zero
        viewController.didMove(toParent: presenter)
        return viewController
    }()

    private lazy var voucherView: VoucherCardView = {
        let topView = createTopView()
        let bottomView = createBottomView()

        return VoucherCardView(model: model.separatorModel,
                               topView: topView,
                               bottomView: bottomView)
    }()

    private lazy var saveButton: UIButton = {
        let accessibilityIdentifier = ViewIdentifierBuilder.build(scopeInstance: "adyen.voucher", postfix: "saveButton")

        return createButton(with: model.style.secondaryButtonStyle,
                            title: model.saveButtonTitle,
                            action: #selector(shareVoucher),
                            accessibilityIdentifier: accessibilityIdentifier)
    }()

    private lazy var appleWalletButton: PKAddPassButton = {
        let button = PKAddPassButton(addPassButtonStyle: .black)
        button.addTarget(self, action: #selector(addToAppleWallet), for: .touchUpInside)
        button.accessibilityIdentifier = ViewIdentifierBuilder.build(scopeInstance: "adyen.voucher", postfix: "appleWalletButton")
        button.preservesSuperviewLayoutMargins = true

        return button
    }()

    private lazy var doneButton: UIButton = {
        let accessibilityIdentifier = ViewIdentifierBuilder.build(scopeInstance: "adyen.voucher", postfix: "doneButton")

        return createButton(with: model.style.mainButtonStyle,
                            title: model.doneButtonTitle,
                            action: #selector(done),
                            accessibilityIdentifier: accessibilityIdentifier)
    }()

    private func createButton(with style: ButtonStyle,
                              title: String,
                              image: UIImage? = nil,
                              action: Selector,
                              accessibilityIdentifier: String) -> UIButton {
        let button = UIButton()
        let titleStyle = style.title
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = titleStyle.font
        button.setTitleColor(titleStyle.color, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 8, left: -2, bottom: 8, right: 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: -2)
        button.layer.borderWidth = style.borderWidth
        button.layer.borderColor = style.borderColor?.cgColor
        button.layer.backgroundColor = style.backgroundColor.cgColor
        button.adyen.round(using: style.cornerRounding)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = accessibilityIdentifier

        return button
    }

    private let model: Model

    internal init(model: Model) {
        self.model = model
        super.init(frame: .zero)
        buildUI()
        backgroundColor = model.style.backgroundColor
    }

    private func buildUI() {
        addVoucherView()
        addAppleWalletButton()
        addShareButton()
        addDoneButton()
    }

    @available(*, unavailable)
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func createTopView() -> UIView {
        fatalError("This is an abstract class that needs to be subclassed.")
    }

    internal func createBottomView() -> UIView {
        fatalError("This is an abstract class that needs to be subclassed.")
    }

    override internal func layoutSubviews() {
        super.layoutSubviews()
        appleWalletButton.adyen.round(using: model.style.mainButtonStyle.cornerRounding)
        saveButton.adyen.round(using: model.style.secondaryButtonStyle.cornerRounding)
        doneButton.adyen.round(using: model.style.mainButtonStyle.cornerRounding)
    }

    private func addVoucherView() {
        voucherView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(voucherView)

        voucherView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        voucherView.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        voucherView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
    }

    private func addAppleWalletButton() {
        guard model.voucherAction.signature != nil else { return }
        addSubview(appleWalletButton)
        appleWalletButton.translatesAutoresizingMaskIntoConstraints = false
        appleWalletButton.widthAnchor.constraint(equalToConstant: 280).isActive = true
        appleWalletButton.topAnchor.constraint(equalTo: voucherView.bottomAnchor, constant: 30).isActive = true
        appleWalletButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }

    private func addShareButton() {
        addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        saveButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true

        if model.voucherAction.signature != nil {
            saveButton.topAnchor.constraint(equalTo: appleWalletButton.bottomAnchor, constant: 30).isActive = true
        } else {
            saveButton.topAnchor.constraint(equalTo: voucherView.bottomAnchor, constant: 30).isActive = true
        }
    }

    private func addDoneButton() {
        addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60).isActive = true
        doneButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        doneButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 16).isActive = true
    }

    @objc private func addToAppleWallet() {
        appleWalletButton.isEnabled = false
        delegate?.saveToAppleWallet(voucherAction: model.voucherAction, presentingViewController: fakeViewController) { [weak self] in
            self?.appleWalletButton.isEnabled = true
        }
    }

    @objc private func shareVoucher() {
        delegate?.saveAsImage(voucherView: voucherView, presentingViewController: fakeViewController)
    }

    @objc private func done() {
        delegate?.didComplete(voucherAction: model.voucherAction, presentingViewController: fakeViewController)
    }

}
