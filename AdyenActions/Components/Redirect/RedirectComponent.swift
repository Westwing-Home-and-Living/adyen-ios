//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import UIKit

/// A component that handles a redirect action. Supports external websites, apps and universal links.
public final class RedirectComponent: ActionComponent, DismissableComponent {
    
    /// Describes the types of errors that can be returned by the component.
    public enum Error: Swift.Error {
        
        /// Indicates that no app is installed that can handle the payment.
        case appNotFound
        
    }
    
    /// :nodoc:
    public weak var delegate: ActionComponentDelegate?
    
    /// Initializes the component.
    ///
    /// - Parameter style: The component's UI style.
    public init(style: RedirectComponentStyle? = nil) {
        self.style = style
    }
    
    /// Handles a redirect action.
    ///
    /// - Parameter action: The redirect action object.
    public func handle(_ action: RedirectAction) {
        Analytics.sendEvent(component: componentName, flavor: _isDropIn ? .dropin : .components, environment: environment)
        
        universalRedirectComponent.handle(action)
    }
    
    /// :nodoc:
    public func dismiss(_ animated: Bool, completion: (() -> Void)?) {
        universalRedirectComponent.dismiss(animated, completion: completion)
    }
    
    /// This function should be invoked from the application's delegate when the application is opened through a URL.
    ///
    /// - Parameter url: The URL through which the application was opened.
    /// - Returns: A boolean value indicating whether the URL was handled by the redirect component.
    @discardableResult
    public static func applicationDidOpen(from url: URL) -> Bool {
        UniversalRedirectComponent.applicationDidOpen(from: url)
    }
    
    /// :nodoc:
    internal lazy var universalRedirectComponent: UniversalRedirectComponent = {
        let component = UniversalRedirectComponent(style: style)
        component.delegate = self
        return component
    }()
    
    /// :nodoc:
    private let style: RedirectComponentStyle?
    
    /// :nodoc:
    private let componentName = "redirect"

}

/// :nodoc:
extension RedirectComponent: ActionComponentDelegate {
    
    /// :nodoc:
    public func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
        delegate?.didProvide(data, from: self)
    }

    /// :nodoc:
    public func didComplete(from component: ActionComponent) {
        delegate?.didComplete(from: self)
    }
    
    /// :nodoc:
    public func didFail(with error: Swift.Error, from component: ActionComponent) {
        delegate?.didFail(with: error, from: self)
    }
    
    /// :nodoc:
    public func didOpenExternalApplication(_ component: ActionComponent) {
        delegate?.didOpenExternalApplication(self)
    }
    
}
