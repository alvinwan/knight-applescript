<img width="50" alt="knight 2x" src="https://user-images.githubusercontent.com/2068077/39094319-73515772-45e2-11e8-99b4-6243bdcc11b2.png">

# Knight

Knight is a Spotlight-esque application that makes common computer tasks accessible via natural language. To use, just **double-tap option**.

- Message anyone. ex: "tell alvin hello", "say hello to derek", "message allen hallelujah".
    - Messaging the same person? No need to specify the name again. ex: "say hello to bob" then "say hello again"
    - Got a long recipient name? No need to type the full name. ex: "say hello to mal" instead of "say hello to malyandi"
- Add event to your calendar using "add event [name] on [date, time] at [location]" ex: add event Meeting at MLK on 4/20 3 p.m.
    - Got an event with keyword `on` or `at`? Just escape the event name using quotes. ex: add event "Meeting on Glade" on today 2 PM
    - By default, Knight looks for a calendar named "Main"
- Type in any URL to access it. e.g., `littlebitbybit.org`
- All other strings are opened in Google search.

To install on Mac OSX (10.10+ required, tested on 10.13.2),

1. Download the Knight application [`Knight_macosx.dmg`](http://github.com/alvinwan/knight/tree/master/Knight_macosx.dmg).
2. Double-click on the `.dmg` file.
3. Drag `Knight` to your Applications folder.
4. Click on the Knight application to run.
5. Double tap the `option` key to open Knight at any time.

## Knight AppleScript Collection
collection of AppleScripts for missing, key functionality. These applescripts are specifically made for dictation users that would like to avoid hitting keys at all costs.

- edit functionality: delete word, delete line, new line
- navigation: switch window, go to next slide, go to last slide

> Note: "New line" exists as "Press return" or "Enter" in default Dictation commands.

If you *don't* have existing custom Dictation commands, simply replace your existing Dictations file with the `.plist` found at the root of this repository.

```
cp knight.plist ~/Library/Preferences/com.apple.speech.recognition.AppleSpeechRecognition.CustomCommands.plist
```

If you *do* have existing custom Dictation commands, (for now) you'll need to import the commands one by one. To do so

1. Open "System Preferences"
2. Click on "Accessibility"
3. Scroll down to "Dictation"
4. Select "Dictation Commands..."
5. Check "Enable advanced commands" in the bottom left.
6. Click on the "+" to create a new command.
7. Type the English trigger.
8. Select "Any Application"
9. Select "Run Workflow" > "Other". In your Finder window, locate this repository's `.scpt` scripts.
