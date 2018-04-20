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
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Register the double control hotkey
        if let keyCombo = KeyCombo(doubledCocoaModifiers: [.option]) {
            let hotKey = HotKey(
                identifier: "doubleOptionTap",
                keyCombo: keyCombo,
                target: self,
                action: #selector(AppDelegate.tappedHotKey))
            hotKey.register()
        }
        
        setupStatusBarIcon()
        setupStatusBarMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        HotKeyCenter.shared.unregisterAll()
    }

    @objc func tappedHotKey() {
        window?.toggleVisibility()
    }
    
    func setupStatusBarIcon() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        }
    }
    
    func setupStatusBarMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(
            title: "Toggle Knight",
            action: #selector(AppDelegate.tappedHotKey), keyEquivalent: "k"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
}

