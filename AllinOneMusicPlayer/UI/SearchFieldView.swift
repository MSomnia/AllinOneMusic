import AppKit

@MainActor
final class SearchFieldView: NSSearchField, NSSearchFieldDelegate {
    var onQueryChanged: ((String) -> Void)?
    var onEscape: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        delegate = self
        placeholderString = "Search"
        sendsSearchStringImmediately = true
        sendsWholeSearchString = false
        controlSize = .large
        font = .systemFont(ofSize: 14)
        focusRingType = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func cancelOperation(_ sender: Any?) {
        stringValue = ""
        onQueryChanged?("")
        onEscape?()
    }

    func controlTextDidChange(_ notification: Notification) {
        onQueryChanged?(stringValue)
    }
}
