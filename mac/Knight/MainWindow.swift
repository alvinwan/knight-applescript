//
//  MainWindow.swift
//  Knight
//
//  Created by Alvin Wan on 4/20/18.
//  Copyright © 2018 Alvin Wan. All rights reserved.
//

import Cocoa

class MainWindow: NSWindow {

    override init(contentRect: NSRect,
                       styleMask style: NSWindow.StyleMask,
                       backing backingStoreType: NSWindow.BackingStoreType,
                       defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.styleMask.insert(.fullSizeContentView)
        self.isOpaque = false
        self.backgroundColor = NSColor.white
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.closeButton)?.isHidden = true
    }
    
}
