//
//  RichTextView.swift
//  qrh
//
//  Displays rendered card body text in a read-only UITextView, so any part of
//  it can be selected and copied (SwiftUI Text only copies whole blocks).
//  Spacing follows the old WebKit CSS: about 14 pt between paragraphs and
//  lists, 8 pt between list items, and a hanging indent for bullets. Words
//  from a search are highlighted.
//

import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var searchHighlight: [SearchTerm] = []
}

struct RichTextView: View {
    let blocks: [RichBlock]

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.searchHighlight) private var highlight
    @Environment(\.openURL) private var openURL

    var body: some View {
        SelectableText(content: .init(blocks: blocks, typeSize: typeSize, highlight: highlight),
                       openURL: openURL)
            .frame(maxWidth: .infinity, alignment: .leading)
    }


//    Blocks to an NSAttributedString, with fonts for the current text size

    static func attributedString(_ blocks: [RichBlock], typeSize: DynamicTypeSize,
                                 highlight: [SearchTerm] = []) -> NSAttributedString {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(typeSize))
        let fonts = Fonts(traits: traits)
        let metrics = UIFontMetrics(forTextStyle: .subheadline)
        let blockSpacing = metrics.scaledValue(for: 14, compatibleWith: traits)
        let itemSpacing = metrics.scaledValue(for: 8, compatibleWith: traits)
        let bulletIndent = metrics.scaledValue(for: 15, compatibleWith: traits)
        let bulletWidth = metrics.scaledValue(for: 36, compatibleWith: traits)

        let result = NSMutableAttributedString()

        func appendParagraph(_ text: NSAttributedString, style: NSParagraphStyle) {
            if result.length > 0 {
                result.append(NSAttributedString(string: "\n", attributes: [.font: fonts.base]))
            }
            let start = result.length
            result.append(text)
            result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: start, length: result.length - start))
        }

        for (index, block) in blocks.enumerated() {
            let after = index == blocks.count - 1 ? 0 : blockSpacing
            switch block {
            case .paragraph(let text):
                let style = NSMutableParagraphStyle()
                style.paragraphSpacing = after
                appendParagraph(convert(text, fonts: fonts), style: style)
            case .bulletList(let items):
                for (itemIndex, item) in items.enumerated() {
                    let style = NSMutableParagraphStyle()
                    style.firstLineHeadIndent = bulletIndent
                    style.headIndent = bulletWidth
                    style.tabStops = [NSTextTab(textAlignment: .natural, location: bulletWidth)]
                    style.paragraphSpacing = itemIndex == items.count - 1 ? after : itemSpacing
                    let line = NSMutableAttributedString(string: "•\t", attributes: [
                        .font: fonts.base, .foregroundColor: UIColor.label,
                    ])
                    line.append(convert(item, fonts: fonts))
                    appendParagraph(line, style: style)
                }
            }
        }

        if !highlight.isEmpty {
            let text = SearchText(result.string)
            for term in highlight {
                for range in text.ranges(of: term) {
                    result.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.4),
                                        range: NSRange(range, in: text.original))
                }
            }
        }
        return result
    }

//    One paragraph or item. Line breaks inside it become line separators, so
//    they keep the paragraph's indent and spacing.

    private static func convert(_ text: AttributedString, fonts: Fonts) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for run in text.runs {
            let string = String(text[run.range].characters).replacingOccurrences(of: "\n", with: "\u{2028}")
            var attributes: [NSAttributedString.Key: Any] = [
                .font: fonts.font(for: run[AttributeScopes.SwiftUIAttributes.FontAttribute.self]),
                .foregroundColor: UIColor.label,
            ]
            if run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            if let link = run.link {
                attributes[.link] = link
            }
            result.append(NSAttributedString(string: string, attributes: attributes))
        }
        return result
    }

//    UIKit fonts for the eight fonts HTMLRenderer uses

    private struct Fonts {
        let base: UIFont
        private let fonts: [Font: UIFont]

        init(traits: UITraitCollection) {
            var fonts = [Font: UIFont]()
            for small in [false, true] {
                let style: UIFont.TextStyle = small ? .footnote : .subheadline
                let plain = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits)
                for bold in [false, true] {
                    for italic in [false, true] {
                        var symbolic = UIFontDescriptor.SymbolicTraits()
                        if bold { symbolic.insert(.traitBold) }
                        if italic { symbolic.insert(.traitItalic) }
                        let descriptor = plain.fontDescriptor.withSymbolicTraits(symbolic) ?? plain.fontDescriptor
                        fonts[HTMLRenderer.font(bold: bold, italic: italic, small: small)] = UIFont(descriptor: descriptor, size: 0)
                    }
                }
            }
            self.fonts = fonts
            self.base = fonts[HTMLRenderer.font()]!
        }

        func font(for font: Font?) -> UIFont {
            font.flatMap { fonts[$0] } ?? base
        }
    }
}


//    Read-only, selectable, non-scrolling text view sized to its content. The
//    attributed text and its measured height are cached, since every page in
//    the stack re-renders when a guideline is pushed.

private struct SelectableText: UIViewRepresentable {
    struct Content: Equatable {
        let blocks: [RichBlock]
        let typeSize: DynamicTypeSize
        let highlight: [SearchTerm]
    }

    let content: Content
    let openURL: OpenURLAction

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.dataDetectorTypes = []
        let accent = UIColor(named: "AccentColor") ?? .link
        view.tintColor = accent
        view.linkTextAttributes = [.foregroundColor: accent]
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.openURL = openURL
        if coordinator.content != content {
            coordinator.content = content
            coordinator.sizes.removeAll()
            view.attributedText = RichTextView.attributedString(content.blocks, typeSize: content.typeSize,
                                                                highlight: content.highlight)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? 10_000
        if let size = context.coordinator.sizes[width] {
            return size
        }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let size = CGSize(width: proposal.width == nil ? fitted.width : width, height: ceil(fitted.height))
        context.coordinator.sizes[width] = size
        return size
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var openURL: OpenURLAction?
        var content: Content?
        var sizes = [CGFloat: CGSize]()

//        Links go through SwiftUI's openURL, so guideline links open in-app
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem,
                      defaultAction: UIAction) -> UIAction? {
            guard case .link(let url) = textItem.content else { return defaultAction }
            return UIAction { [openURL] _ in openURL?(url) }
        }

//        No preview menu for guideline links (they aren't web pages)
        func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem,
                      defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            if case .link(let url) = textItem.content, url.scheme == LinkDetector.scheme {
                return nil
            }
            return UITextItem.MenuConfiguration(menu: defaultMenu)
        }
    }
}

#if DEBUG
#Preview("Rich text") {
    RichTextView(blocks: PreviewData.richBlocks)
        .padding()
}

#Preview("Rich text highlighted") {
    RichTextView(blocks: PreviewData.richBlocks)
        .environment(\.searchHighlight, SearchTerm.terms(in: "underline anaesthetists"))
        .padding()
}
#endif
