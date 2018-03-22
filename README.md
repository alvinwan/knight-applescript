# Knight
collection of AppleScripts for missing, key functionality
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
