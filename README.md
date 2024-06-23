# AudioRecorder: A Comprehensive Audio Recording App (Simulator Tested Only)

## Disclaimer:
Due to hardware limitations, this project has only been tested on a simulator and may require adjustments for real-world device 
- Not tested on Device, as my MacBook is old and device is new, hence cannot install latest OS in Mac and was not able to run on device, have only tested on simulator which might not be accurate. So there can be few issues in device which I might not have handled.

This project implements a full-featured audio recording application with extensive functionality.

## Features:

### Recording:
1. Start, Stop, Pause, and Resume recording.
2. Saves audio to a single file.
3. Displays recording duration.

### Playback:
1. Play recorded audio.
2. Stop playback.
3. Displays playback duration.

### Background and Foreground Recording:
- Records audio seamlessly in both background and foreground states.

### App Termination Handling:
- Stops recording gracefully upon app termination.

### App Interruption Handling:
- Pauses recording during interruptions like phone calls.

### Continuous Audio Recording:
- Writes audio chunks continuously to a file.

### Protocol-Based Architecture:
- Audio recording and playback are protocol-based, allowing for easy integration with third-party libraries in the future.

### Thread Safety:
- Ensures thread safety for concurrent operations.

### Error Handling:
- Implements proper error handling with a dedicated error enum.

## Architecture:

### MVVM with Combine:
- Leverages MVVM architecture with Combine for data binding and UI updates.

### SnapKit:
- Employs SnapKit for creating a user-friendly interface.

### Protocol-Oriented Design:
- Utilizes protocols extensively to promote code scalability and flexibility.

### Unit Testing:
- Includes unit tests for the view model, incorporating mocking for dependencies.

### API Documentation:
- Provides proper documentation for all public APIs.

### SOLID Principles:
- Adheres to SOLID principles for maintainable and loosely coupled code.

## Project Structure:

- **Core**: Contains core application components like audio recorder, player, and file manager.
- **Support**: Houses supporting files such as storyboards and assets.
- **UI**: Encompasses UI logic and its associated view model.
- **Utilities**: Includes utility classes like extensions and reusable code.
- **RecorderTests**: Contains unit test files and mock classes.

## Limitations and Future Enhancements:

### Current Limitations:
1. **UI Focus**: The current implementation prioritizes functionality over UI aesthetics.
2. **AVAudioEngine Support (Untested)**: While code for AVAudioEngine is included, simulator limitations prevent testing.
3. **Test Coverage**: Full test coverage is not yet achieved.
4. **Video Recording**: Video recording functionality is not implemented due to device limitations.

### Potential Improvements:
1. **Enhanced File Management**: The `AudioFileManager` class can be extended to support features like saving to custom paths, file deletion, and purging mechanisms based on size or expiry.
2. **UI Playback Controls**: Integrate pause and resume functionality for audio playback within the UI.
3. **Improved UI/UX Design**: Invest in refining the user interface and user experience for optimal usability.
4. **Logging**: Replace print statements with a dedicated logging system.
5. **Error Handling UI**: Implement user-friendly alerts or notifications for error handling.
6. **Expanded Testing**: Increase test coverage by including recorder, player, and UI tests.
7. **Separate Timer Class**: Consider extracting the timer functionality into a dedicated class for better organization.
