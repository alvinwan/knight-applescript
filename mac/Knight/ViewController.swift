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

    @IBOutlet weak var statusBox: NSBox!
    @IBOutlet weak var statusText: NSTextField!
    
    let viewWidth: CGFloat = 800
    let viewHeight: CGFloat = 70
    
    override func viewDidLoad() {
        self.view.setFrameSize(NSMakeSize(viewWidth, viewHeight))
    }
    
    @IBAction func textFieldEnter(sender: NSTextField) {
        let string = sender.stringValue
        hideWindowStatus()
        
        let handlers: [KnightHandler] = [
            SendMessageHandler(),
            AppleScriptHandler(),
            AddCalendarEventHandler(),
            CalendarAvailabilities(),
            BrowserHandler()
        ]
        
        var isError: Bool, error: String
        for handler in handlers {
            if handler.shouldHandle(string: string) {
                (isError, error) = handler.handle(string: string)
                if isError {
                    showWindowError(string: error)
                } else {
                    clearAndClose(sender: sender)
                }
                break
            }
        }
    }
    
    func hideWindowStatus() {
        var frame = self.view.window?.frame
        frame?.size = NSSize(width: viewWidth, height: viewHeight)
        self.view.window?.setFrame(frame!, display: true, animate: true)
    }
    
    func showWindowStatus(numLines: CGFloat) {
        var frame = self.view.window?.frame
        frame?.size = NSSize(width: viewWidth, height: viewHeight + 10 + numLines * 20)
        self.view.window?.setFrame(frame!, display: true, animate: true)
    }
    
    func showWindowError(string: String) {
        statusText.stringValue = string
        showWindowStatus(numLines: string.count(string: "\n") + 1)
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
        return string.starts(with: "\(self.prefix):")
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
    
    func handle(string: String) -> (Bool, String) {
        if (invocation != nil) {
            return safeHandle(string: string)
        } else {
            return (true, "Error: No appropriate handle found for handler.")
        }
    }
    
    func safeHandle(string: String) -> (Bool, String) {
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
    
    override func safeHandle(string: String) -> (Bool, String) {
        let information = invocation!.parse(string: string)
        return AppleScriptHandler.runAppleScript(appleScript: information["content"] as! String)
    }
    
    static func runAppleScript(appleScript: String) -> (Bool, String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                return (false, output.stringValue ?? "")
            } else if (error != nil) {
                return (true, "error: \(String(describing: error))")
            }
        }
        return (true, "error: could not access applescript")
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
    
    override func safeHandle(string: String) -> (Bool, String) {
        var url: String = string
        if BrowserHandler.verifyUrl(urlString: url) {
            if !url.starts(with: "http") {
                url = "http://" + url
            }
        } else {
            url = "https://www.google.com/search?q=" + url
        }
        return AppleScriptHandler.runAppleScript(appleScript: "open location \"\(url)\"")
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
    
    override func handle(string: String) -> (Bool, String) {
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
        return AppleScriptHandler.runAppleScript(appleScript: appleScript)
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
 *      add event <event name> [on <start date>] [at <location>] [for <duration in hours>]
 *      add event Meeting (Bit by Bit) at MLK on 4/20 3 PM
 *      add event "Walla for Walla" for 0.5 on tomorrow 9:00 a.m.
 *
 * If your event name contains key words such as "on" or "at," enclose your event name in double
 * quotes.
 */
class AddCalendarEventHandler: KnightHandler {
    
    var calendarName: String = "Main"
    
    override init() {
        super.init()
        invocations.append(AddEventInvocation())
    }
    
    override func safeHandle(string: String) -> (Bool, String)  {
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
        return AppleScriptHandler.runAppleScript(appleScript: appleScript)
    }
    
    static func parseHumanReadableEvent(string: String) -> [String: Any] {
        
        var facets: [String: [String]] = [:]
        let keywords = [
            "startDate": ["on"],
            "location": ["at"],
            "durationHours": ["for"]
        ]
        
        var facetKey = "eventName"
        var quoteOn = false
        var word: String
        wordLoop: for word_ in string.components(separatedBy: " ") {
            word = word_
            facets[facetKey] = (facets[facetKey] ?? [])
            
            // handle quoted strings - does not handle escaped quotes
            if word.hasPrefix("\"") || word.hasSuffix("\"") {
                quoteOn = !quoteOn
                word = word.hasPrefix("\"") ? String(word[1...]) : String(word[..<1])
            }
            
            if quoteOn {
                facets[facetKey]!.append(word)
                continue
            }
            
            // identify event property
            for (key, triggers) in keywords {
                for trigger in triggers {
                    if word == trigger {
                        facetKey = key
                        continue wordLoop
                    }
                }
            }
            
            facets[facetKey]!.append(word)
        }
        
        let eventName = facets["eventName"]?.joined(separator: " ")
        let startDate = cleanDateTime(words:facets["startDate"]!)
        let location = facets["location"]?.joined(separator: " ")
        
        var durationHours: Float = 1
        print(facets)
        if (facets["durationHours"] != nil) {
            durationHours = Float(facets["durationHours"]![0])!
        }
        
        return [
            "eventName": eventName ?? "",
            "startDate": startDate,
            "location": location ?? "",
            "durationHours": durationHours
        ]
    }
    
    /**
     * Smarter parsing
     * ---------------
     * for dates and times. Adds support for the following conveniences:
     *
     * - 3 PM (single-digit hour)
     * - "today", "tomorrow"
     * - <month>/<date> (implicitly adding the year)
     *
     * Note that AppleScript already supports other human-readable dates and time formats (e.g., p.m.)
     * TODO: support day-of-week + "next" or "last"
     */
    static func cleanDateTime(words: [String]) -> String {
        let dateToday = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd/yy")
        
        var cleanedWords: [String] = []
        
        for word in words {
            if word.lowercased().trim() == "today" {
                cleanedWords.append(dateFormatter.string(from: dateToday))
            } else if word.lowercased().trim() == "tomorrow" {
                let dateTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: dateToday)
                cleanedWords.append(dateFormatter.string(from: dateTomorrow!))
            } else if let num = Int(word) {
                cleanedWords.append("\(num):00")
            } else if word.contains("/") && word.count(string: "/") == 1 {
                dateFormatter.setLocalizedDateFormatFromTemplate("yy")
                let year = dateFormatter.string(from: dateToday)
                cleanedWords.append("\(word)/\(year)")
            } else {
                cleanedWords.append(word)
            }
        }
        
        return cleanedWords.joined(separator: " ")
    }
    
    class AddEventInvocation: KnightHandlerInvocation {
        
        func recognize(string: String) -> Bool {
            return string.lowercased().starts(with: "add event ") && string.contains(word: "on")
        }
        
        func parse(string: String) -> [String: Any] {
            let array = string.split(separator:" ", maxSplits: 2).map(String.init)
            return AddCalendarEventHandler.parseHumanReadableEvent(string: array[2])
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
    
    override func safeHandle(string: String) -> (Bool, String) {
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
        return AppleScriptHandler.runAppleScript(appleScript: appleScript)
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
    
    func count(string: String) -> CGFloat {
        return CGFloat(self.components(separatedBy: string).count) - 1
    }
    
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        get {
            return self[..<index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeThrough<Int>) -> Substring {
        get {
            return self[...index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeFrom<Int>) -> Substring {
        get {
            return self[index(startIndex, offsetBy: value.lowerBound)...]
        }
    }
}
