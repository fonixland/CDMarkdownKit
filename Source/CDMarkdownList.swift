//
//  CDMarkdownList.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
//
//  Copyright © 2016-2018 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownList: CDMarkdownLevelElement {

    fileprivate static let regex = "^\\s*([\\*\\+\\-]{1,%@})[ \t]+(.+)$"
//    fileprivate static let regex = "^\\s*([\\*\\+\\-]{1,})(.+)$"
    
    open var maxLevel: Int
    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var separator: String
    open var indicator: String

    open var regex: String {
        let level: String = maxLevel > 0 ? "\(maxLevel)" : ""
        return String(format: CDMarkdownList.regex,
                      level)
//        return String(format: CDMarkdownList.regex)
    }

    public init(font: CDFont? = nil,
                maxLevel: Int = 0,
                indicator: String = "•",
                separator: String = " ",
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil) {
        self.maxLevel = maxLevel
        self.indicator = indicator
        self.separator = separator
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 0
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = 0
            paragraphStyle.lineSpacing = 1.38
            self.paragraphStyle = paragraphStyle
        }
    }

    open func formatText(_ attributedString: NSMutableAttributedString,
                         range: NSRange,
                         level: Int) {
        let previousRange = NSRange(location: range.location-4, length: 4)
        if attributedString.attributedSubstring(from: previousRange).string == "    " {
            attributedString.replaceCharacters(in: range,
                with: "◦\(separator)")
        }
        else {
            attributedString.replaceCharacters(in: range,
                                               with: "\(indicator)\(separator)")
        }
        
    }

    open func addFullAttributes(_ attributedString: NSMutableAttributedString,
                                range: NSRange,
                                level: Int) {
//        let indicatorSize = "\(indicator) ".sizeWithAttributes(attributes)
//        let separatorSize = separator.sizeWithAttributes(attributes)
//        let floatLevel = CGFloat(level)
        guard let paragraphStyle = self.paragraphStyle else { return }
        let updatedParagraphStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
//        updatedParagraphStyle.headIndent = indicatorSize.width + (separatorSize.width * floatLevel)
//        updatedParagraphStyle.firstLineHeadIndent = updatedParagraphStyle.headIndent

        attributedString.addParagraphStyle(updatedParagraphStyle,
                                           toRange: range)
    }

    open func addAttributes(_ attributedString: NSMutableAttributedString,
                            range: NSRange,
                            level: Int) {
        attributedString.addAttributes(attributesForLevel(level-1),
                                       range: range)
    }
    
    func listMatches(for pattern: String, inString string: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let range = NSRange(string.startIndex..., in: string)
        let matches = regex.matches(in: string, options: [], range: range)
        
        return matches.map {
            let range = Range($0.range, in: string)!
            return String(string[range])
        }
    }
    
    func replaceMatches(for pattern: String, inString string: String, withString replacementString: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return string
        }
        
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: replacementString)
    }
}
