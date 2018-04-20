//
//  AppDelegate.swift
//  Knight
//
//  Created by Alvin Wan on 4/19/18.
//  Copyright © 2018 Alvin Wan. All rights reserved.
//

import Cocoa
import Magnet

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if let keyCombo = KeyCombo(doubledCocoaModifiers: .command) {
            let hotKey = HotKey(identifier: "CommandDoubleTap", keyCombo: keyCombo, target: self, action: #selector(AppDelegate.tappedHotKey))
            hotKey.register() // or HotKeyCenter.shared.register(with: hotKey)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        HotKeyCenter.shared.unregisterAll()
    }

    @objc func tappedHotKey() {
        if (window != nil && window!.isVisible) {
            window?.close()
        } else {
            window?.makeKeyAndOrderFront(self)
        }
    }
}

