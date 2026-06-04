//
//  Caption.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 04/06/26.
//
import UIKit
internal import WebKit
internal import Speech
import AVFoundation

extension LiveViewController {

    func setupCaptionLabel() {
        captionLabel.numberOfLines = 1
        captionLabel.lineBreakMode = .byClipping
        captionLabel.adjustsFontSizeToFitWidth = false
    }

    func resetCaptionBuilding() {
        stopScrolling()
        accumulatedCaption = ""
        currentGlossQueue.removeAll()
        currentQueueIndex = 0
        isSpellingMode = false
        currentSpellingWord = ""; currentSpellingIndex = 0
        needsSpaceBeforeNext = false
        captionLabel.attributedText = nil
    }

    func addToCaptionAndHighlight(wordOrLetter: String, isCompleteWord: Bool) {
        if needsSpaceBeforeNext && !accumulatedCaption.isEmpty {
            accumulatedCaption += " "
            needsSpaceBeforeNext = false
        }
        accumulatedCaption += wordOrLetter
        if isCompleteWord { needsSpaceBeforeNext = true }
        let start = accumulatedCaption.count - wordOrLetter.count
        updateCaptionDisplay(highlightRange: NSRange(location: start, length: wordOrLetter.count))
    }

    func updateCaptionDisplay(highlightRange: NSRange) {
        stopScrolling()
        captionLabel.layer.sublayerTransform = CATransform3DIdentity

        let font = captionLabel.font ?? UIFont.systemFont(ofSize: 17)
        let labelWidth = captionLabel.bounds.width
        guard labelWidth > 0 else { return }

        let fullText = accumulatedCaption
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .kern: NSNumber(value: 0)]

        func measureWidth(_ text: String) -> CGFloat {
            guard !text.isEmpty else { return 0 }
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 200),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs, context: nil)
            return ceil(rect.width)
        }

        let fullAttr = NSMutableAttributedString(string: fullText, attributes: attrs)
        fullAttr.addAttribute(.foregroundColor, value: UIColor.black,
                              range: NSRange(location: 0, length: fullText.count))
        if highlightRange.location + highlightRange.length <= fullText.count {
            fullAttr.addAttribute(.foregroundColor, value: UIColor.systemBlue,
                                  range: highlightRange)
        }

        guard measureWidth(fullText) > labelWidth else {
            captionLabel.attributedText = fullAttr; return
        }

        // Overflow: pin active word to right edge
        let textUpToEnd = (fullText as NSString)
            .substring(to: highlightRange.location + highlightRange.length)
        let windowEnd = measureWidth(textUpToEnd) + 6
        let windowStart = max(0, windowEnd - labelWidth)

        var cumWidth: CGFloat = 0
        var startCharIndex = 0
        for i in 0..<fullText.count {
            let ch = (fullText as NSString).substring(with: NSRange(location: i, length: 1))
            let chWidth = measureWidth(ch)
            if cumWidth + chWidth > windowStart { startCharIndex = i; break }
            cumWidth += chWidth
            startCharIndex = i + 1
        }

        let sliceStart = fullText.index(fullText.startIndex, offsetBy: startCharIndex)
        let visibleString = String(fullText[sliceStart...])
        let visibleAttr = NSMutableAttributedString(
            string: visibleString,
            attributes: [.font: font, .foregroundColor: UIColor.black])

        let newLoc = highlightRange.location - startCharIndex
        if newLoc >= 0 && (newLoc + highlightRange.length) <= visibleString.count {
            visibleAttr.addAttribute(.foregroundColor, value: UIColor.systemBlue,
                                     range: NSRange(location: newLoc, length: highlightRange.length))
        }
        captionLabel.attributedText = visibleAttr
    }

    func stopScrolling() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        captionLabel.layer.sublayerTransform = CATransform3DIdentity
    }
}
