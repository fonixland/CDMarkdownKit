//
//  CDMarkdownParser.swift
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

open class CDMarkdownParser {

    // MARK: - Element Arrays
    fileprivate var escapingElements: [CDMarkdownElement]
    fileprivate var defaultElements: [CDMarkdownElement]
    fileprivate var unescapingElements: [CDMarkdownElement]

    open var customElements: [CDMarkdownElement]

    // MARK: - Basic Elements
    public let header: CDMarkdownHeader
    public let list: CDMarkdownList
    public let quote: CDMarkdownQuote
    public let link: CDMarkdownLink
    public let automaticLink: CDMarkdownAutomaticLink
    public let boldItalic: CDMarkdownBoldItalic
    public let bold: CDMarkdownBold
    public let italic: CDMarkdownItalic
    public let underline: CDMarkdownUnderline
    public let code: CDMarkdownCode
    public let syntax: CDMarkdownSyntax
#if os(iOS) || os(macOS) || os(tvOS)
    public let image: CDMarkdownImage
#endif

    // MARK: - Escaping Elements
    fileprivate var codeEscaping = CDMarkdownCodeEscaping()
    fileprivate var escaping = CDMarkdownEscaping()
    fileprivate var unescaping = CDMarkdownUnescaping()

    // MARK: - Configuration
    // Enables or disables detection of URLs even without Markdown format
    open var automaticLinkDetectionEnabled: Bool = true
    public let font: CDFont
    public let fontColor: CDColor
    public let backgroundColor: CDColor
    public let paragraphStyle: NSParagraphStyle

    // MARK: - Initializer
    public init(font: CDFont = CDFont.systemFont(ofSize: 11),
                boldItalicFont: CDFont? = nil,
                boldFont: CDFont? = nil,
                italicFont: CDFont? = nil,
                underlineFont: CDFont? = nil,
                fontColor: CDColor = CDColor.black,
                backgroundColor: CDColor = CDColor.clear,
                paragraphStyle: NSParagraphStyle? = nil,
                imageSize: CGSize? = nil,
                automaticLinkDetectionEnabled: Bool = true,
                customElements: [CDMarkdownElement] = []) {
        self.font = font
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacing = 0
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.lineSpacing = 1.38
            self.paragraphStyle = paragraphStyle
        }

        header = CDMarkdownHeader(font: font,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        list = CDMarkdownList(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        quote = CDMarkdownQuote(font: font,
                                color: fontColor,
                                backgroundColor: backgroundColor,
                                paragraphStyle: paragraphStyle)
        link = CDMarkdownLink(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        automaticLink = CDMarkdownAutomaticLink(font: font,
                                                color: fontColor,
                                                backgroundColor: backgroundColor,
                                                paragraphStyle: paragraphStyle)
        boldItalic = CDMarkdownBoldItalic(font: font,
                                          customBoldItalicFont: boldItalicFont,
                                          color: fontColor,
                                          backgroundColor: backgroundColor,
                                          paragraphStyle: paragraphStyle)
        bold = CDMarkdownBold(font: font,
                              customBoldFont: boldFont,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        italic = CDMarkdownItalic(font: font,
                                  customItalicFont: italicFont,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        underline = CDMarkdownUnderline(font: font,
                                  customUnderlineFont: underlineFont,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
        code = CDMarkdownCode(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
        syntax = CDMarkdownSyntax(font: font,
                                  color: fontColor,
                                  backgroundColor: backgroundColor,
                                  paragraphStyle: paragraphStyle)
#if os(iOS) || os(macOS) || os(tvOS)
        image = CDMarkdownImage(font: font,
                                color: fontColor,
                                backgroundColor: backgroundColor,
                                paragraphStyle: paragraphStyle,
                                size: imageSize)
#endif

        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.escapingElements = [codeEscaping, escaping]
#if os(iOS) || os(macOS) || os(tvOS)
        self.defaultElements = [header, list, quote, link, automaticLink, boldItalic, bold, italic, underline, image]
#else
        self.defaultElements = [header, list, quote, link, automaticLink, boldItalic, bold, italic, underline]
#endif
        self.unescapingElements = [code, syntax, unescaping]
        self.customElements = customElements
    }

    // MARK: - Element Extensibility
    open func addCustomElement(_ element: CDMarkdownElement) {
        customElements.append(element)
    }

    open func removeCustomElement(_ element: CDMarkdownElement) {
        guard let index = customElements.index(where: { someElement -> Bool in
            return element === someElement
        }) else {
            return
        }
        customElements.remove(at: index)
    }

    // MARK: - Parsing
    open func parse(_ markdown: String) -> NSAttributedString {
        return parse(NSAttributedString(string: markdown))
    }

    open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: markdown)
        let mutableString = attributedString.mutableString
        mutableString.replaceOccurrences(of: "\n\n+",
                                         with: "\n",
                                         options: .regularExpression,
                                         range: NSRange(location: 0,
                                                        length: mutableString.length))
        mutableString.replaceOccurrences(of: "&nbsp;",
                                         with: " ",
                                         range: NSRange(location: 0,
                                                        length: mutableString.length))
        // space-space-newline hack
        mutableString.replaceOccurrences(of: "  [\n|\r|\r\n]",
                                         with: "\n\n",
                                         range: NSRange(location: 0,
                                                        length: mutableString.length))
        let regExp = try? NSRegularExpression(pattern: "^[^\\t\\_\\d+\\+\\-\\*\\# +\\w+]",
//        let regExp = try? NSRegularExpression(pattern: "^\\s+",
                                              options: .anchorsMatchLines)
        if let regExp = regExp {
            regExp.replaceMatches(in: mutableString,
                                  options: [],
                                  range: NSRange(location: 0,
                                                 length: mutableString.length),
                                  withTemplate: "")
        }
        
        let regExpList = try? NSRegularExpression(pattern: "\\n[ ]{1,4}", options: .anchorsMatchLines)
        if let regExpList = regExpList {
            regExpList.replaceMatches(in: mutableString,
                                      options: [],
                                      range: NSRange(location: 0,
                                                     length: mutableString.length),
                                      withTemplate: "\n    ")
        }
        
        let range = NSRange(location: 0,
                            length: attributedString.length)

        attributedString.addFont(font,
                                 toRange: range)
        attributedString.addForegroundColor(fontColor,
                                            toRange: range)
        attributedString.addBackgroundColor(backgroundColor,
                                            toRange: range)
        attributedString.addParagraphStyle(paragraphStyle,
                                           toRange: range)

        var elements: [CDMarkdownElement] = escapingElements
        elements.append(contentsOf: defaultElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)
        elements.forEach { element in
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
//                if type(of: element) == CDMarkdownUnderline.self {
//                    let textRange = NSMakeRange(40, 50)
//                    attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
//                }
                element.parse(attributedString)
            }
        }
        return attributedString
    }
}
