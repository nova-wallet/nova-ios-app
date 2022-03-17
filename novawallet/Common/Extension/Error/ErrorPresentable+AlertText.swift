import Foundation
import RobinHood

struct ErrorContent {
    let title: String
    let message: String
}

protocol ErrorContentConvertible {
    func toErrorContent(for locale: Locale?) -> ErrorContent
}

extension ErrorPresentable where Self: AlertPresentable {
    func presentErrorOrUndefined(error: Error, from view: ControllerBackedProtocol?, locale: Locale?) {
        if !present(error: error, from: view, locale: locale) {
            _ = present(error: CommonError.undefined, from: view, locale: locale)
        }
    }

    func present(error: Error, from view: ControllerBackedProtocol?, locale: Locale?) -> Bool {
        let optionalContent: ErrorContent? = {
            if let contentConvertibleError = error as? ErrorContentConvertible {
                return contentConvertibleError.toErrorContent(for: locale)
            }

            if error as? BaseOperationError != nil {
                let title = R.string.localizable.operationErrorTitle(preferredLanguages: locale?.rLanguages)
                let message = R.string.localizable.operationErrorMessage(preferredLanguages: locale?.rLanguages)

                return ErrorContent(title: title, message: message)
            }

            if (error as NSError).domain == NSURLErrorDomain {
                let title = R.string.localizable.connectionErrorTitle(preferredLanguages: locale?.rLanguages)
                let message = R.string.localizable.connectionErrorMessage_v2_2_0(preferredLanguages: locale?.rLanguages)

                return ErrorContent(title: title, message: message)
            }

            return nil
        }()

        guard let content = optionalContent else {
            return false
        }

        let closeAction = R.string.localizable.commonClose(preferredLanguages: locale?.rLanguages)

        present(message: content.message, title: content.title, closeAction: closeAction, from: view)

        return true
    }
}
