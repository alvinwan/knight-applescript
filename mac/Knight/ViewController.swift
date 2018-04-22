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
        if (SendMessageHandler.shouldHandle(string: string)) {
            SendMessageHandler.handle(string: string)
        } else if (AppleScriptHandler.shouldHandle(string: string)) {
            AppleScriptHandler.handle(string: string)
        } else if (AddCalendarEventHandler.shouldHandle(string: string)) {
            AddCalendarEventHandler.handle(string: string)
        } else if (CalendarAvailabilities.shouldHandle(string: string)) {
            CalendarAvailabilities.handle(string: string)
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
 *      applescript: <code>
 *      applescript: open location "http://google.com"
 */
class AppleScriptHandler {
    
    static func shouldHandle(string: String) -> Bool {
        return string.starts(with: "applescript:")
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
 *      <search term or URL>
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
 *      message <name>: <message>
 *      message alvin: hello there
 *
 * Searches for all recipients whose name start with the provided string. This means that the user can
 * message recipients by mentioning just a first name. This additionally performs a lookup for the
 * user's phone number, so that iMessage is forcibly used.
 */
class SendMessageHandler {
    
    static func shouldHandle(string: String) -> Bool {
        return (string != "" && string.starts(with: "message "))
    }
    
    static func handle(string: String) {
        let array = string.split(separator:":", maxSplits: 1).map(String.init)
        let prefixArray = array[0].split(separator: " ", maxSplits: 1).map(String.init)
        let recipient = prefixArray[1]
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


/**
 * Add Calendar Event
 * ------------------
 * adds specified event to calendar
 *
 *      add event <event name> on <start date> at <location>
 *      add event Meeting (Bit by Bit) on 4/20/18 3:00 PM at MLK
 *
 * Caveat: case-sensitive for "on" and "at" keywords. Does not recongize "p.m."
 * Should recognize days of the week.
 */
class AddCalendarEventHandler {
    
    static var calendarName: String = "Main"
    
    static func shouldHandle(string: String) -> Bool {
        return string.lowercased().starts(with: "add event ") && string.range(of: "on") != nil
    }
    
    static func handle(string: String) {
        let array = string.components(separatedBy: " on ")  // needs more robust checking for words
        
        let prefixArray = array[0].split(separator:" ", maxSplits: 2).map(String.init)
        let eventName = prefixArray[2]
        
        var startDate: String, location: String;
        if string.range(of: " at ") != nil {
            let contentArray = array[1].components(separatedBy: " at ")
            startDate = cleanDateTime(string: contentArray[0])
            location = contentArray[1]
        } else {
            startDate = cleanDateTime(string: array[1])
            location = ""
        }
        let durationHours = 1
        
        let appleScript = """
        -- save path to original app
        set originalApp to path to frontmost application as text
        
        set theStartDate to date \"\(startDate)\"
        set theEndDate to theStartDate + (\(durationHours) * hours)

        tell application "Calendar"
            tell calendar \"\(calendarName)\"
        make new event with properties {summary: \"\(eventName)\", start date:theStartDate, end date:theEndDate, location: \"\(location)\"}
            end tell
        end tell
        
        -- return to original app
        activate application originalApp
        """
        print(AppleScriptHandler.runAppleScript(appleScript: appleScript))
    }
    
    /**
     * "Smarter" parsing for dates and times
     */
    static func cleanDateTime(string: String) -> String {
        var cleanedDateTime = string
        let dateToday = Date()
        let dateFormatter = DateFormatter()
        var readableDate: String = ""
        dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd/yy")
        
        if string.lowercased().range(of: "today") != nil {
            readableDate = dateFormatter.string(from: dateToday)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "today", with: readableDate)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "Today", with: readableDate) // TODO: ugly
        } else if string.lowercased().range(of: "tomorrow") != nil {
            let dateTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: dateToday)
            readableDate = dateFormatter.string(from: dateTomorrow!)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "tomorrow", with: readableDate)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "Tomorrow", with: readableDate) // TODO: ugly
        }
        
        return cleanedDateTime
    }
}

/**
 * Check Calendar Availabilities
 * -----------------------------
 * Automatically generates human-readable list of availabilties during business hours
 *
 *      availabilities
 *
 * Once generated, the app should toggle back to the original application and paste at the
 * cursor position.
 */
class CalendarAvailabilities {
    
    static var startHour = 9
    static var endHour = 17
    static var calendarName: String = "Main"
    
    static func shouldHandle(string: String) -> Bool {
        return string.starts(with:"availabilities")
    }
    
    static func handle(string: String) {
        let appleScript = """
        -- the current timestamp
        set now to (current date)
        -- midnight this morning
        set today to now - (time of now)
        -- midnight tomorrow morning
        set tomorrow to (today) + (24 * 60 * 60)
        -- list of output lines
        set output to {}
        tell application "Calendar"
            -- iterate upcoming tasks, excepting repeating tasks not repeating today
            repeat with e in ((every event in \"\(calendarName)\") whose (start date) is greater than or equal to today and (start date) is less than tomorrow and (start date) is not in (excluded dates))
                -- properly note tasks lasting all day
                if (allday event of e) then
                    set output to output & ("all day")
                else
                    set startDate to (start date of e)
                    set endDAte to (end date of e)
                    set startTime to (time string of startDate)
                    set endTime to (time string of endDAte)
                    if (count of startTime) is less than 11 then
                        set startTime to " " & startTime
                    end if
                    if (count of endTime) is less than 11 then
                        set endTime to " " & endTime
                    end if
                    set output to output & (startTime & " - " & endTime)
                end if
            end repeat
        end tell
        """
        print(AppleScriptHandler.runAppleScript(appleScript: appleScript))
    }
}
