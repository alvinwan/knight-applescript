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

        // hide title bar
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.styleMask.insert(.fullSizeContentView)
        
        // hide title bar buttons
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        
        // prettify parts left
        self.isOpaque = false
        self.backgroundColor = NSColor.white
    }
    
    func toggleVisibility() {
        if (!isVisible || occlusionState.rawValue != 8194) {
            makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            close()
            // figure out how to restore refocus on original window
        }
    }
}
