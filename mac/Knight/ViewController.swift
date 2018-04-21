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
        let string = sender.stringValue
        if (MessageHandler.shouldHandle(string: string)) {
            MessageHandler.handle(string: string)
        } else if (AppleScriptHandler.shouldHandle(string: string)) {
            AppleScriptHandler.handle(string: string)
        } else if (BrowserHandler.shouldHandle(string: string)) {
            BrowserHandler.handle(string: string)
        }
        clearAndClose(sender: sender)
    }
    
    func clearAndClose(sender: NSTextField) {
        sender.stringValue = ""
        self.view.window?.close()
    }
}


/**
 * AppleScript Handler
 * --------------------
 * Run the provided appleScript snippet
 *
 *      applescript: [code]
 *      applescript: open location "http://google.com"
 */
class AppleScriptHandler {
    
    static func shouldHandle(string: String) -> Bool {
        return string.starts(with: "applescript ")
    }
    
    static func handle(string: String) {
        let array = string.split(separator:":", maxSplits: 1).map(String.init);
        let appleScript = array[1]
        print(runAppleScript(appleScript: appleScript))
    }
    
    static func runAppleScript(appleScript: String) -> String {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                return output.stringValue ?? ""
            } else if (error != nil) {
                return "error: \(String(describing: error))"
            }
        }
        return "error: could not access applescript"
    }
}


/**
 * Browser Handler
 * ---------------
 * Search term or visit URL.
 *
 *      [search term or URL]
 *      google.com
 *      define bear
 *
 * Catch-all last resort for Knight summons. If the string is URL-esque, attempt to open the URL.
 * Otherwise, perform a Google search.
 */
class BrowserHandler {
    
    static func shouldHandle(string: String) -> Bool {
        return true
    }
    
    static func handle(string: String) {
        var url: String = string
        if BrowserHandler.verifyUrl(urlString: url) {
            if !url.starts(with: "http") {
                url = "http://" + url
            }
        } else {
            url = "https://www.google.com/search?q=" + url
        }
        print(AppleScriptHandler.runAppleScript(appleScript: "open location \"\(url)\""))
    }
    
    static func verifyUrl(urlString: String?) -> Bool {
        let urlRegEx = "(https?://(www.)?)?[-a-zA-Z0-9@:%._+~#=]{2,256}\\.[a-z]{2,6}([-a-zA-Z0-9@:%_+.~#?&//=]*)"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        return urlTest.evaluate(with: urlString)
    }
}


/**
 * Message Handler
 * ---------------
 * Messages the specified recipient, delimited by a colon
 *
 *      [name]: [message]
 *      alvin: hello there
 *
 * Searches for all recipients whose name start with the provided string. This means that the user can
 * message recipients by mentioning just a first name. This additionally performs a lookup for the
 * user's phone number, so that iMessage is forcibly used.
 */
class MessageHandler {
    
    static func shouldHandle(string: String) -> Bool {
        return (string != "" && string.contains(":"))
    }
    
    static func handle(string: String) {
        let array = string.split(separator:":", maxSplits: 1).map(String.init)
        let recipient = array[0]
        let message = array[1]
        
        let appleScript = """
        -- save path to original app
        set originalApp to path to frontmost application as text
        
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
        
        -- return to original app
        activate application originalApp
        """
        print(AppleScriptHandler.runAppleScript(appleScript: appleScript))
    }
}
