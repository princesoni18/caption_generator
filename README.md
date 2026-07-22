# Whisper Captions Generator

A modern Flutter application that generates `.srt` (SubRip Subtitle) files locally from audio/video files using the Whisper AI model. 

## Features

- **Local Processing**: Transcribes audio directly on your device using `whisper_ggml` for enhanced privacy and offline capability.
- **English & Hinglish Support**: Generates captions in standard English or transliterates Hindi to Hinglish.
- **Fast Execution**: Utilizes multi-threading and optimized playback speeds for quicker transcription.
- **SRT Generation**: Outputs standard `.srt` format, compatible with almost all media players and video editors.
- **Local History**: Keeps track of all your generated subtitle files for easy access.
- **Dark Mode UI**: Beautiful, modern interface utilizing Google Fonts (Outfit).
- **Background Notifications**: Get notified when your transcription is complete.

## Technology Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **AI Model**: [Whisper](https://openai.com/research/whisper) via `whisper_ggml`
- **Other Key Packages**:
  - `file_picker`: For selecting local audio/video files.
  - `indic_transliteration_dart`: For Devnagari to Latin (Hinglish) transliteration.
  - `flutter_local_notifications`: For transcription progress and completion alerts.
  - `ffmpeg_kit_flutter_new`: Media format handling.

## Getting Started

### Prerequisites
- Flutter SDK (>=3.4.4 <4.0.0)
- Dart SDK
- Android Studio / Xcode for running on mobile devices

### Installation

1. Clone the repository:
   ```bash
   git clone <your-repository-url>
   cd caption_generator
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## How it Works

1. **Launch App**: The app will initially download the required Whisper GGML model on first launch.
2. **Select Media**: Choose an audio or video file using the file picker.
3. **Choose Language Mode**: Select standard English or Hinglish output.
4. **Transcribe**: The app will process the audio locally and generate an `.srt` file.
5. **View/Use SRT**: You can view the generated file in the history screen or find it in your device's Downloads/Documents folder.

## Permissions

The app requires the following permissions (managed via `permission_handler`):
- Storage/Media access to pick audio/video files and save the generated `.srt` files.
- Notification permissions to show transcription progress.
