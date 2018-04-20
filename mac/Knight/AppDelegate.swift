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

    weak var window: MainWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Register the command double-tap hotkey
        if let keyCombo = KeyCombo(doubledCocoaModifiers: .command) {
            let hotKey = HotKey(
                identifier: "CommandDoubleTap",
                keyCombo: keyCombo,
                target: self,
                action: #selector(AppDelegate.tappedHotKey))
            hotKey.register()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        HotKeyCenter.shared.unregisterAll()
    }

    @objc func tappedHotKey() {
        if (window != nil) {
            window!.toggleVisibility()
        }
    }
}

