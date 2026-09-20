import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        extractAndRedirect()
    }

    private func extractAndRedirect() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(urlType) {
                provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] (item, _) in
                    if let url = item as? URL {
                        self?.saveAndOpenMainApp(url: url.absoluteString)
                    } else if let urlStr = item as? String {
                        self?.saveAndOpenMainApp(url: urlStr)
                    }
                }
                return
            } else if provider.hasItemConformingToTypeIdentifier(textType) {
                provider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] (item, _) in
                    if let text = item as? String, let extractedURL = self?.findURL(in: text) {
                        self?.saveAndOpenMainApp(url: extractedURL)
                    }
                }
                return
            }
        }

        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func findURL(in text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url?.absoluteString
    }

    private func saveAndOpenMainApp(url: String) {
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let deepLink = URL(string: "chefpocket://import?url=\(encodedURL)") else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        // Open host application via openURL selector
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self

        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: deepLink)
                break
            }
            responder = r.next
        }

        // Backup to clipboard for flawless fallback
        UIPasteboard.general.string = url

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
