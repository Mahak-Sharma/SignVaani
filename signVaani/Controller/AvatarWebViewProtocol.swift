import UIKit
import WebKit
//Protocol-like a blueprint any class that adopts this must have these properties/methods...
//Anyobject matlab sirf classes hi use karsakti hai protocol ko 
protocol AvatarWebViewProtocol: AnyObject {
    var webView: WKWebView! { get }
}
//Default Implementation (reusable setupWebView logic)
extension AvatarWebViewProtocol {
    // Loads the avatar HTML page — same logic for bottom screens
    func setupWebView() {
        webView.isHidden = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.isUserInteractionEnabled = false

        // Configure WebView for file access
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // Enable JavaScript
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Try to find the HTML file in bundle
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            print("Found avatar HTML at: \(url.path)")

            if FileManager.default.isReadableFile(atPath: url.path) {
                print("HTML file is readable")
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                print("Loading avatar from: \(url.lastPathComponent)")
            } else {
                print("HTML file is not readable")
                loadFallbackAvatar()
            }
        } else {
            print("Avatar HTML file not found in bundle")
            loadFallbackAvatar()
        }
    }

    // Fallback avatar agar HTML file bundle mein na mile
    func loadFallbackAvatar() {
        print("Loading fallback avatar")

        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    font-family: Arial, sans-serif;
                }
                .avatar-container {
                    text-align: center;
                    color: white;
                }
                .avatar-circle {
                    width: 150px;
                    height: 150px;
                    background: rgba(255,255,255,0.2);
                    border-radius: 50%;
                    margin: 0 auto 20px;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    font-size: 60px;
                    animation: pulse 2s infinite;
                }
                @keyframes pulse {
                    0% { transform: scale(1); }
                    50% { transform: scale(1.1); }
                    100% { transform: scale(1); }
                }
                .avatar-text { font-size: 24px; margin-bottom: 10px; }
                .gloss-text  { font-size: 18px; opacity: 0.9; }
                #glossDisplay { font-weight: bold; color: #ffd700; }
            </style>
        </head>
        <body>
            <div class="avatar-container">
                <div class="avatar-circle">👤</div>
                <div class="avatar-text">Sign Language Avatar</div>
                <div class="gloss-text">Current Gloss: <span id="glossDisplay">...</span></div>
            </div>
            <script>
                let lastGloss = null;
                let currentTimer = null;

                function currentGlossLabel(word) {
                    return Array.isArray(word) ? 'animation' : word;
                }

                function finishFallbackPlayback() {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.avatarDone) {
                        window.webkit.messageHandlers.avatarDone.postMessage("done");
                    }
                }

                function playGlossFromJSON(word) {
                    lastGloss = word;
                    document.getElementById('glossDisplay').textContent = currentGlossLabel(word);
                    const circle = document.querySelector('.avatar-circle');
                    circle.style.transform = 'scale(1.2)';
                    setTimeout(() => {
                        circle.style.transform = 'scale(1)';
                        finishFallbackPlayback();
                    }, 500);
                }

                function pauseGlossPlayback() {}

                function resumeGlossPlayback() {
                    if (lastGloss !== null) {
                        playGlossFromJSON(lastGloss);
                    }
                }

                function rewindGlossPlayback() {
                    if (lastGloss !== null) {
                        playGlossFromJSON(lastGloss);
                    }
                }

                function forwardGlossPlayback() {
                    if (lastGloss !== null) {
                        playGlossFromJSON(lastGloss);
                    }
                }

                function restartGlossPlayback() {
                    if (lastGloss !== null) {
                        playGlossFromJSON(lastGloss);
                    }
                }

                function replayLastGloss() {
                    if (lastGloss !== null) {
                        playGlossFromJSON(lastGloss);
                    }
                }

                function stopGlossPlayback() {
                    document.getElementById('glossDisplay').textContent = '...';
                    document.querySelector('.avatar-circle').style.transform = 'scale(1)';
                }
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(htmlString, baseURL: nil)
        print("Fallback avatar loaded")
    }
}
