//
//  ViewController.swift
//  Knight
//
//  Created by Alvin Wan on 4/19/18.
//  Copyright © 2018 Alvin Wan. All rights reserved.
//

import Cocoa
import CoreFoundation

class ViewController: NSViewController {

    @IBAction func textFieldEnter(sender: NSTextField) {
        if (MessageHandler.shouldHandle(string: sender.stringValue)) {
            MessageHandler.handle(string: sender.stringValue)
        }
        clearAndClose(sender: sender)
    }
    
    func clearAndClose(sender: NSTextField) {
        sender.stringValue = ""
        self.view.window?.close()
    }
}


class MessageHandler {
    
    static func shouldHandle(string: String) -> Bool {
        return (string != "" && string.contains(":"))
    }
    
    static func handle(string: String) {
        let array = string.split(separator:":", maxSplits: 1).map(String.init)
        let sender = array[0]
        let message = array[1]
        
        let proc = Process()
        proc.launchPath = "/usr/bin/osascript"
        proc.arguments = ["/Users/alvinwan/Downloads/message.scpt", sender, message]
        proc.launch()  // figure out how to include applescript with app
    }
}
