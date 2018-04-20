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
        (NSApplication.shared.delegate as! AppDelegate).window = self.window as! MainWindow
    }
}

