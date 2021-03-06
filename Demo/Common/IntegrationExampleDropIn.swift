//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//
import Adyen
import AdyenActions
import AdyenCard
import AdyenDropIn
import AdyenComponents
import UIKit

extension IntegrationExample {

    // MARK: - DropIn Component

    internal func presentDropInComponent() {
        guard let paymentMethods = paymentMethods else { return }
        let configuration = DropInComponent.PaymentMethodsConfiguration(clientKey: Configuration.clientKey)
        configuration.applePay.merchantIdentifier = Configuration.applePayMerchantIdentifier
        configuration.applePay.summaryItems = Configuration.applePaySummaryItems
        configuration.environment = environment
        configuration.localizationParameters = nil
        configuration.payment = payment

        let dropInComponentStyle = DropInComponent.Style()
        let component = DropInComponent(paymentMethods: paymentMethods,
                                        paymentMethodsConfiguration: configuration,
                                        style: dropInComponentStyle,
                                        title: Configuration.appName)
        component.delegate = self
        currentComponent = component

        presenter?.present(viewController: component.viewController, completion: nil)
    }

    // MARK : - Payment response handling

    fileprivate func paymentResponseHandler(result: Result<PaymentsResponse, Error>) {
        switch result {
        case let .success(response):
            if let action = response.action {
                handle(action)
            } else {
                finish(with: response.resultCode)
            }
        case let .failure(error):
            finish(with: error)
        }
    }

    private func handle(_ action: Action) {
        guard paymentInProgress else { return }
        (currentComponent as? DropInComponent)?.handle(action)
    }
}

extension IntegrationExample: DropInComponentDelegate {

    internal func didSubmit(_ data: PaymentComponentData, from component: DropInComponent) {
        paymentInProgress = true
        let request = PaymentsRequest(data: data)
        apiClient.perform(request, completionHandler: paymentResponseHandler)
    }

    internal func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        let request = PaymentDetailsRequest(details: data.details,
                                            paymentData: data.paymentData,
                                            merchantAccount: Configuration.merchantAccount)
        apiClient.perform(request, completionHandler: paymentResponseHandler)
    }

    internal func didComplete(from component: DropInComponent) {
        paymentInProgress = false
        finish(with: .authorised)
    }

    internal func didFail(with error: Error, from component: DropInComponent) {
        paymentInProgress = false
        finish(with: error)
    }

    internal func didCancel(component: PaymentComponent, from dropInComponent: DropInComponent) {
        // Handle the event when the user closes a PresentableComponent.
        print("User did close: \(component)")
    }

}
