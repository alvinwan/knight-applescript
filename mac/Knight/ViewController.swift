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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func textFieldEnter(sender: NSTextField) {
        if (sender.stringValue != "" && sender.stringValue.contains(":")) {
            let array = sender.stringValue.split(separator:":", maxSplits: 1).map(String.init)
            let sender = array[0]
            let message = array[1]
            
            let proc = Process()
            proc.launchPath = "/usr/bin/osascript"
            proc.arguments = ["/Users/alvinwan/Downloads/message.scpt", sender, message]
            proc.launch()  // figure out how to include applescript with app
            
            self.view.window?.close()
        }
    }
}

