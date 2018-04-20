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
        let recipient = array[0]
        let message = array[1]
        
        let myAppleScript = """
        -- grab user's phone number
        tell application "Contacts"
            set buddyPhone to value of phone 1 of (person 1 whose name starts with \"\(recipient)\") whose (label = "mobile" or label = "iPhone" or label = "home" or label = "work")
        end tell
        
        -- send message with phone number, using iMessage
        tell application "Messages"
            set targetService to 1st service whose service type = iMessage
            set targetBuddy to buddy buddyPhone of targetService
            send \"\(message)\" to targetBuddy
        end tell
        
        tell application "System Events" to keystroke tab using command down
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                print(output.stringValue ?? "(Message sent successfully to \(recipient))")
            } else if (error != nil) {
                print("error: \(String(describing: error))")
            }
        }
    }
}
