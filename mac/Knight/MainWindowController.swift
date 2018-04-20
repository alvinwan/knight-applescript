//
//  WindowController.swift
//  Knight
//
//  Created by Alvin Wan on 4/19/18.
//  Copyright © 2018 Alvin Wan. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        (NSApplication.shared.delegate as! AppDelegate).window = self.window
    }
}

