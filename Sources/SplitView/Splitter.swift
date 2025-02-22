//
//  Splitter.swift
//  SplitView
//
//  Created by Steven Harris on 8/18/21.
//

/// Custom splitters must conform to SplitDivider, just like the default `Splitter`.
public protocol SplitDivider: View {
    var styling: SplitStyling { get }
}

import SwiftUI

/// The Splitter that separates the `primary` from `secondary` views in a `Split` view.
///
/// The Splitter holds onto `styling`, which is accessed by Split to determine the `visibleThickness` by which
/// the `primary` and `secondary` views are separated. The `styling` also publishes `previewHide`, which
/// specifies whether we are previewing what Split will look like when we hide a side. The Splitter uses `previewHide`
/// to change its `dividerColor` to `.clear` when being previewed, while Split uses it to determine whether the
/// spacing between views should be `visibleThickness` or zero.
public struct Splitter: SplitDivider {
    
    @EnvironmentObject private var layout: LayoutHolder
    @ObservedObject public var styling: SplitStyling
    @State private var dividerColor: Color  // Changes based on styling.previewHide
    private var color: Color { privateColor ?? styling.color }
    private var inset: CGFloat { privateInset ?? styling.inset }
    private var visibleThickness: CGFloat { privateVisibleThickness ?? styling.visibleThickness }
    private var invisibleThickness: CGFloat { privateInvisibleThickness ?? styling.invisibleThickness }
    private let privateColor: Color?
    private let privateInset: CGFloat?
    private let privateVisibleThickness: CGFloat?
    private let privateInvisibleThickness: CGFloat?
    
    // Defaults
    public static var defaultColor: Color = Color.gray
    public static var defaultInset: CGFloat = 6
    public static var defaultVisibleThickness: CGFloat = 4
    public static var defaultInvisibleThickness: CGFloat = 30

    public var body: some View {
        ZStack {
            switch layout.value {
            case .horizontal:
                Color.clear
                    .frame(width: invisibleThickness)
                    .padding(0)
                RoundedRectangle(cornerRadius: visibleThickness / 2)
                    .fill(dividerColor)
                    .frame(width: visibleThickness)
                    .padding(EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0))
            case .vertical:
                Color.clear
                    .frame(height: invisibleThickness)
                    .padding(0)
                RoundedRectangle(cornerRadius: visibleThickness / 2)
                    .fill(dividerColor)
                    .frame(height: visibleThickness)
                    .padding(EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset))
            }
        }
        .contentShape(Rectangle())
        .task { dividerColor = color } // Otherwise, styling.color does not appear at open
        // If we are previewing hiding a side using drag-to-hide, then we make the color .clear.
        .onChange(of: styling.previewHide) { hide in
            dividerColor = hide ? .clear : privateColor ?? color
        }
        // Perhaps should consider some kind of custom hoverEffect, since the cursor change
        // on hover doesn't work on iOS.
        .onHover { inside in
            #if targetEnvironment(macCatalyst) || os(macOS)
            // With nested split views, it's possible to transition from one Splitter to another,
            // so we always need to pop the current cursor (a no-op when it's the only one). We
            // may or may not push the hover cursor depending on whether it's inside or not.
            NSCursor.pop()
            if inside {
                layout.isHorizontal ? NSCursor.resizeLeftRight.push() : NSCursor.resizeUpDown.push()
            }
            #endif
        }
    }
    
    public init(color: Color? = nil, inset: CGFloat? = nil, visibleThickness: CGFloat? = nil, invisibleThickness: CGFloat? = nil) {
        privateColor = color
        privateInset = inset
        privateVisibleThickness = visibleThickness
        privateInvisibleThickness = invisibleThickness
        styling = SplitStyling(color: color, inset: inset, visibleThickness: visibleThickness, invisibleThickness: invisibleThickness)
        _dividerColor = State(initialValue: color ?? Self.defaultColor)
    }
    
    public init(styling: SplitStyling) {
        privateColor = styling.color
        privateInset = styling.inset
        privateVisibleThickness = styling.visibleThickness
        privateInvisibleThickness = styling.invisibleThickness
        self.styling = styling
        _dividerColor = State(initialValue: styling.color)
    }
    
}

struct Splitter_Previews: PreviewProvider {
    static var previews: some View {
        Splitter()
            .environmentObject(LayoutHolder(.horizontal))
        Splitter(color: Color.red, inset: 2, visibleThickness: 8, invisibleThickness: 30)
            .environmentObject(LayoutHolder(.horizontal))
        Splitter.line()
            .environmentObject(LayoutHolder(.horizontal))
        Splitter()
            .environmentObject(LayoutHolder(.vertical))
        Splitter(color: Color.red, inset: 2, visibleThickness: 8, invisibleThickness: 30)
            .environmentObject(LayoutHolder(.vertical))
        Splitter.line()
            .environmentObject(LayoutHolder(.vertical))
    }
}
