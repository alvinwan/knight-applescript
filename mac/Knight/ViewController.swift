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
        
        let handlers: [KnightHandler] = [
            SendMessageHandler(),
            AppleScriptHandler(),
            AddCalendarEventHandler(),
            CalendarAvailabilities(),
            BrowserHandler()
        ]
        
        for handler in handlers {
            if handler.shouldHandle(string: string) {
                handler.handle(string: string)
                clearAndClose(sender: sender)
                break
            }
        }
    }
    
    func clearAndClose(sender: NSTextField) {
        sender.stringValue = ""
        self.view.window?.close()
    }
}


protocol KnightHandlerInvocation {
    
    func recognize(string: String) -> Bool
    func parse(string: String) -> [String: Any]
}

class DefaultHandlerInvocation: KnightHandlerInvocation {
    
    var prefix: String?
    
    init(prefix: String) {
        self.prefix = prefix
    }
    
    func recognize(string: String) -> Bool {
        return string.starts(with: "\(string):")
    }
    
    func parse(string: String) -> [String: Any] {
        return ["content": string.split(separator: ":", maxSplits: 1).map(String.init)[1]]
    }
}

class KnightHandler {
    
    var invocations: [KnightHandlerInvocation] = []
    var invocation: KnightHandlerInvocation?
    
    func shouldHandle(string: String) -> Bool {
        for invocation in invocations {
            if invocation.recognize(string: string) {
                self.invocation = invocation
                return true
            }
        }
        return false
    }
    
    func handle(string: String) {
        if (invocation != nil) {
            safeHandle(string: string)
        } else {
            print("Error: No appropriate handle found for handler.")
        }
    }
    
    func safeHandle(string: String) {
        fatalError("Handlers must implement handle method.")
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
class AppleScriptHandler: KnightHandler {
    
    override init() {
        super.init()
        invocations.append(DefaultHandlerInvocation(prefix: "applescript"))
    }
    
    override func safeHandle(string: String) {
        let information = invocation!.parse(string: string)
        print(AppleScriptHandler.runAppleScript(appleScript: information["content"] as! String))
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
class BrowserHandler: KnightHandler {
    
    override init() {
        super.init()
        invocations.append(DummyHandlerInvocation())
    }
    
    override func safeHandle(string: String) {
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
    
    class DummyHandlerInvocation: KnightHandlerInvocation {
        
        func recognize(string: String) -> Bool {
            return true
        }
        
        func parse(string: String) -> [String : Any] {
            return [:]
        }
    }
}


/**
 * Message Handler
 * ---------------
 * Messages the specified recipient, delimited by a colon
 *
 *      say <message> to <name>
 *      say hello there to alvin
 *
 *      message <name>: <message>
 *      message alvin: hello there
 *
 *      <name>::<message>
 *      alvin::hello there
 *
 *
 * Searches for all recipients whose name start with the provided string. This means that the user can
 * message recipients by mentioning just a first name. This additionally performs a lookup for the
 * user's phone number, so that iMessage is forcibly used.
 */
class SendMessageHandler: KnightHandler {
    
    override init() {
        super.init()
        invocations.append(MessageInvocation())
        invocations.append(DoubleColonInvocation())
        invocations.append(SayToInvocation())
    }
    
    override func handle(string: String) {
        let information = invocation!.parse(string: string)
        let recipient = (information["recipient"]! as! String).trim()
        let message = information["message"]!
        
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
    
    class MessageInvocation: KnightHandlerInvocation {
        
        func recognize(string: String) -> Bool {
            return string.starts(with: "message")
        }
        
        func parse(string: String) -> [String: Any] {
            let array = string.split(separator:":", maxSplits: 1).map(String.init)
            let prefixArray = array[0].split(separator: " ", maxSplits: 1).map(String.init)
            let recipient = prefixArray[1]
            let message = array[1]
            return ["recipient": recipient, "message": message]
        }
    }
    
    class DoubleColonInvocation: KnightHandlerInvocation {
        
        func recognize(string: String) -> Bool {
            return string.contains("::")
        }
        
        func parse(string: String) -> [String: Any] {
            let array = string.components(separatedBy: "::")
            return ["recipient": array[0], "message": array[1]]
        }
    }
    
    class SayToInvocation: KnightHandlerInvocation {
        
        func recognize(string: String) -> Bool {
            return string.starts(with: "say ") && string.contains(word: "to")
        }
        
        func parse(string: String) -> [String: Any] {
            var array = string.components(separatedBy: "say ")
            let range = array[1].range(of: " to ", options: .backwards)!
            let recipient = String(array[1][range.upperBound...])
            let message = String(array[1][..<range.lowerBound])
            return ["recipient": recipient, "message": message]
        }
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
class AddCalendarEventHandler: KnightHandler {
    
    var calendarName: String = "Main"
    
    override init() {
        super.init()
        invocations.append(AddEventInvocation())
    }
    
    override func safeHandle(string: String) {
        let information = invocation!.parse(string: string)
        
        let startDate = information["startDate"]!
        let durationHours = information["durationHours"]!
        let location = information["location"]!
        let eventName = information["eventName"]!
        
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
    
    static func parseHumanReadableEvent(string: String) -> [String: Any] {
        let array = string.components(separatedBy: " on ")  // needs more robust checking for words
        
        let eventName = array[0]
        
        var startDate: String, location: String;
        if string.contains(word: "at") {
            let contentArray = array[1].components(separatedBy: " at ")
            startDate = cleanDateTime(string: contentArray[0])
            location = contentArray[1]
        } else {
            startDate = cleanDateTime(string: array[1])
            location = ""
        }
        let durationHours = 1
        
        return [
            "eventName": eventName,
            "startDate": startDate,
            "location": location,
            "durationHours": durationHours
        ]
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
        
        if string.lowercased().contains(string: "today") {
            readableDate = dateFormatter.string(from: dateToday)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "today", with: readableDate)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "Today", with: readableDate) // TODO: ugly
        } else if string.lowercased().contains(string: "tomorrow") {
            let dateTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: dateToday)
            readableDate = dateFormatter.string(from: dateTomorrow!)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "tomorrow", with: readableDate)
            cleanedDateTime = cleanedDateTime.replacingOccurrences(of: "Tomorrow", with: readableDate) // TODO: ugly
        }
        
        return cleanedDateTime
    }
    
    class AddEventInvocation: KnightHandlerInvocation {
        
        func recognize(string: String) -> Bool {
            return string.lowercased().starts(with: "add event ") && string.contains(word: "on")
        }
        
        func parse(string: String) -> [String: Any] {
            let array = string.split(separator:" ", maxSplits: 2).map(String.init)
            return AddCalendarEventHandler.parseHumanReadableEvent(string: array[1])
        }
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
class CalendarAvailabilities: KnightHandler {
    
    var startHour = 9
    var endHour = 17
    var calendarName: String = "Main"
    
    override init() {
        super.init()
        invocations.append(DefaultHandlerInvocation(prefix: "availabilities"))
    }
    
    override func safeHandle(string: String) {
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

extension String {
    func contains(word: String) -> Bool {
        return self.range(of: "\\b\(word)\\b", options: .regularExpression) != nil
    }
    
    func contains(string: String) -> Bool {
        return self.range(of: string) != nil
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
