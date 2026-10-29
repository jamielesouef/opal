//
//  AppKitColor.swift
//  Opal
//
//  Created by Jamie Le Souef on 29/10/2026.
//

import AppKit

public enum AppKitColor {
    public static var accent: NSColor { NSColor.controlAccentColor }
    public static var calloutFill: NSColor { accent.withAlphaComponent(AppOpacity.callout) }
    public static var tagFill: NSColor { accent.withAlphaComponent(AppOpacity.tag) }
    public static var unresolvedLink: NSColor { accent.withAlphaComponent(AppOpacity.unresolved) }
    public static var highlight: NSColor { NSColor.systemYellow.withAlphaComponent(AppOpacity.highlight) }
    public static var codeFill: NSColor { NSColor.quaternarySystemFill }
    public static var divider: NSColor { NSColor.separatorColor }
    public static var text: NSColor { NSColor.textColor }
    public static var secondaryText: NSColor { NSColor.secondaryLabelColor }
    public static var quietText: NSColor { NSColor.quaternaryLabelColor }
    public static var editorBackground: NSColor { NSColor.textBackgroundColor }
}
