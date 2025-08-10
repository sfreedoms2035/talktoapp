# Transcription Debug Guide - Main Screen Issue

## Current Problem
The user reports that transcription in the main screen is not working without pushing the "Test Transcription" button. This guide provides step-by-step debugging to identify the root cause.

## Debugging Steps

### Step 1: Check Console Output During App Startup

When the app starts, look for these initialization messages in the console:

```
Initializing speech recognition...
Speech recognition initialized: true
Starting continuous listening for trigger word detection...
Starting continuous listening loop...
```

**If you DON'T see these messages:**
- The voice service is not initializing properly
- Check microphone permissions in device settings

### Step 2: Check Microphone Button State

1. Look at the microphone button on the main screen
2. It should show "Microphone Active - Tap to Deactivate" when working
3. The button should be RED when active

**If the button shows "Microphone Inactive":**
- The automatic listening is not starting
- Try pressing the microphone button to activate it manually

### Step 3: Test Manual Activation

1. Press the microphone button to activate listening
2. Check console for these messages:
```
Starting speech-to-text continuous listening...
Starting continuous listening for trigger word detection...
Starting continuous listening loop...
Starting new listening session for continuous listening...
```

**If you see these messages but still no transcription:**
- The listening is starting but not capturing audio
- Check if another app is using the microphone

### Step 4: Check Audio Capture

1. With microphone active, speak clearly into the device
2. Look for these console messages:
```
Starting speech recognition...
Speech recognition status: listening
Setting last recognized text in listen: [your speech]
Calling onTextRecognized callback in listen with: [your speech]
```

**If you DON'T see "Setting last recognized text":**
- Audio is not being captured
- Check microphone permissions
- Try speaking louder or closer to the microphone

### Step 5: Check UI Updates

1. If you see transcription in console but not in UI
2. Look for the "Transcribed Text" section on the main screen
3. It should update with your speech

**If console shows transcription but UI doesn't update:**
- There's a UI callback issue
- The setState() might not be working properly

### Step 6: Compare with Test Button

1. Press "Test Transcription" button
2. Speak the same words
3. Compare console output with automatic listening

**If Test Button works but automatic doesn't:**
- The issue is in the continuous listening implementation
- The callback setup might be different

## Common Issues and Solutions

### Issue 1: Microphone Permission
**Symptoms:** No audio capture, permission errors
**Solution:**
1. Go to Settings > Apps > TalkToApp > Permissions
2. Enable Microphone permission
3. Restart the app

### Issue 2: Another App Using Microphone
**Symptoms:** Audio capture fails, "microphone busy" errors
**Solution:**
1. Close all other apps that might use microphone
2. Restart the device if necessary
3. Try again

### Issue 3: Continuous Listening Not Starting
**Symptoms:** No continuous listening messages in console
**Solution:**
1. Check if `_isAutoListening` is true
2. Verify voice service is initialized
3. Try manual microphone activation

### Issue 4: Audio Captured But UI Not Updating
**Symptoms:** Console shows transcription, UI shows "No speech detected"
**Solution:**
1. Check if callback is properly set
2. Verify setState() is being called
3. Check for any exceptions in callback

### Issue 5: Transcription Method Confusion
**Symptoms:** Inconsistent behavior between modes
**Solution:**
1. Check which transcription method is active (Whisper vs Speech-to-Text)
2. Try switching methods using the toggle button
3. Ensure the correct service is initialized

## Detailed Console Debug Checklist

When testing, look for this exact sequence of messages:

### App Startup:
```
✓ Initializing speech recognition...
✓ Speech recognition initialized: true
✓ Voice service ready.
✓ Starting continuous listening for trigger word detection...
✓ Starting continuous listening loop...
```

### Microphone Activation:
```
✓ Starting speech-to-text continuous listening...
✓ Starting new listening session for continuous listening...
✓ Starting speech recognition...
✓ Speech recognition status: listening
```

### Speech Detection:
```
✓ Setting last recognized text in listen: [your words]
✓ Calling onTextRecognized callback in listen with: [your words]
✓ Continuous listening received text: [your words]
```

### UI Update:
```
✓ UI should show your transcribed text in "Transcribed Text" section
```

## Quick Fix Attempts

### Fix 1: Reset App State
1. Press "Reset App" button
2. Wait for initialization to complete
3. Activate microphone manually
4. Test speech recognition

### Fix 2: Switch Transcription Method
1. Press the transcription method toggle button
2. Switch from Speech-to-Text to Whisper (or vice versa)
3. Test again

### Fix 3: Restart App
1. Close the app completely
2. Reopen the app
3. Wait for full initialization
4. Test transcription

### Fix 4: Check Device Settings
1. Go to device Settings
2. Check microphone permissions for TalkToApp
3. Ensure no other apps are using microphone
4. Test in a quiet environment

## Expected vs Actual Behavior

### Expected Behavior:
1. App starts and initializes voice service
2. Microphone button shows "Active" 
3. Speaking triggers transcription automatically
4. Text appears in "Transcribed Text" section
5. Trigger word "hey" automatically processes request

### If Test Button Works But Automatic Doesn't:
This indicates:
- Voice service is working correctly
- The issue is in the continuous listening loop
- Callback mechanism might be different between manual and automatic modes

## Reporting Debug Information

When reporting the issue, please include:

1. **Console Output:** Copy all console messages from app startup to speech attempt
2. **Microphone Button State:** Active or Inactive
3. **Transcription Method:** Whisper or Speech-to-Text
4. **Device Info:** Android version, device model
5. **Test Button Result:** Does manual test work?
6. **Environment:** Quiet or noisy, distance from microphone

## Next Steps Based on Findings

### If No Console Messages:
- Voice service initialization failed
- Check permissions and restart app

### If Console Shows Listening But No Transcription:
- Audio capture issue
- Check microphone hardware and permissions

### If Console Shows Transcription But UI Doesn't Update:
- UI callback issue
- Check for JavaScript/Dart exceptions

### If Everything Looks Correct But Still Not Working:
- Timing issue in continuous listening loop
- May need to modify the listening implementation
