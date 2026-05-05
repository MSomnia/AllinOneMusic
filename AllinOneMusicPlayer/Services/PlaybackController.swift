import Foundation

@MainActor
final class PlaybackController {
    private let webViewManager: WebViewManager

    private let controlSelectors: [PlatformID: [MediaAction: [String]]] = [
        .youtube: [
            .playPause: ["#play-pause-button"],
            .next: [".next-button"],
            .previous: [".previous-button"],
        ],
        .spotify: [
            .playPause: ["[data-testid=\"control-button-playpause\"]"],
            .next: ["[data-testid=\"control-button-skip-forward\"]"],
            .previous: ["[data-testid=\"control-button-skip-back\"]"],
        ],
        .netease: [
            .playPause: [
                "#g_player .btns a.ply",
                "#g_player .btns a.pas",
                ".m-player .btns a.ply",
                ".m-player .btns a.pas",
                "a[data-action=\"play\"]",
                "a[data-action=\"pause\"]",
                "a.ply",
                "a.pas",
                ".btnplay",
            ],
            .next: [
                "#g_player .btns a.nxt",
                ".m-player .btns a.nxt",
                "a[data-action=\"next\"]",
                "a.nxt",
                ".btnNext",
            ],
            .previous: [
                "#g_player .btns a.prv",
                ".m-player .btns a.prv",
                "a[data-action=\"prev\"]",
                "a.prv",
                ".btnPrev",
            ],
        ],
    ]

    init(webViewManager: WebViewManager) {
        self.webViewManager = webViewManager
    }

    func send(_ action: MediaAction, to platform: PlatformID) {
        guard
            let selectors = controlSelectors[platform]?[action],
            let webView = webViewManager.playbackWebView(for: platform),
            let script = Self.clickScript(selectors: selectors)
        else {
            return
        }

        webView.evaluateJavaScript(script) { _, error in
            if let error {
                StartupLogger.log("PlaybackController \(platform.rawValue) \(action.title) error: \(error.localizedDescription)")
            }
        }
    }

    private static func clickScript(selectors: [String]) -> String? {
        guard let encodedSelectors = selectors.jsonEncoded else {
            StartupLogger.log("PlaybackController failed to encode selectors: \(selectors)")
            return nil
        }

        return """
        (() => {
          const selectors = \(encodedSelectors);
          const clickInDocument = (doc) => {
            for (const selector of selectors) {
              const element = doc.querySelector(selector);
              if (!element) continue;
              setTimeout(() => {
                element.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true, view: window }));
                element.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true, view: window }));
                element.click();
              }, 0);
              return selector;
            }
            return null;
          };

          const mainSelector = clickInDocument(document);
          if (mainSelector) return { clicked: true, selector: mainSelector, frame: false };

          for (const frame of Array.from(document.querySelectorAll('iframe'))) {
            try {
              if (!frame.contentDocument) continue;
              const frameSelector = clickInDocument(frame.contentDocument);
              if (frameSelector) return { clicked: true, selector: frameSelector, frame: true };
            } catch (_) {}
          }

          return { clicked: false, selectors };
        })();
        """
    }
}

private extension Encodable {
    var jsonEncoded: String? {
        let data = try? JSONEncoder().encode(self)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
}
