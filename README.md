# Breathe With Me

A minimalist iOS wellness app combining guided breathing exercises, Pomodoro focus technique, and sleep timer for complete mind-body balance.

## Features

### Breathe
- **Guided Breathing Cycles**: 4-phase breathing pattern (Breathe In → Hold → Breathe Out → Hold)
- **Multiple Durations**: Choose from 30 seconds, 1 minute, 2 minutes, or 5 minutes
- **Beautiful Animations**: Smooth, calming circle animations synchronized with your breathing

### Focus
- **Pomodoro Timer**: Classic 25-minute work sessions with scheduled breaks
- **Smart Break System**: Automatic alternation between short (5 min) and long (15 min) breaks
- **Session Tracking**: Count your completed Pomodoros
- **Visual Progress**: Circular progress indicator with color-coded modes

### Sleep
- **Sleep Timer**: Peaceful countdown timer to help you drift off
- **Flexible Durations**: Choose from 15, 30, 45, or 60 minutes
- **Calming Visuals**: Moonlit interface with gentle pulsing animations
- **Night Mode**: Dark theme perfect for bedtime

### Design
- **Minimalist Interface**: Clean design with context-appropriate colors
- **Tab Navigation**: Easy switching between Breathe, Focus, and Sleep modes
- **Smooth Transitions**: Elegant animations throughout

## Requirements

- Xcode 15.0 or later
- iOS 15.0 or later
- Swift 5.0

## How to Open and Preview on MacBook

### Method 1: Using Finder
1. Navigate to the project folder in Finder: `BreatheWithMe`
2. Double-click on `BreatheWithMe.xcodeproj`
3. Xcode will open automatically

### Method 2: Using Terminal
1. Open Terminal app
2. Navigate to the project directory:
   ```bash
   cd ~/Documents/BreatheWithMe
   ```
3. Open the project in Xcode:
   ```bash
   open BreatheWithMe.xcodeproj
   ```

### Running the App
1. Once Xcode opens, look at the top toolbar
2. Click on the device selector (next to the Play/Stop buttons)
3. Choose an iOS simulator from the dropdown menu:
   - **iPhone 15 Pro** (recommended)
   - iPhone 14 Pro
   - iPhone SE
   - Or any other available simulator
4. Click the **Play button** (▶️) or press `Cmd + R`
5. Wait for the app to build (first build may take a minute)
6. The iOS simulator will launch and run your app

### First Time Setup
- If prompted to "Trust" or allow developer mode, click **Trust** or **Always Allow**
- If Xcode asks to install additional components, allow the installation
- Make sure you have the latest iOS simulators installed (Xcode → Settings → Platforms)

## Usage

### Breathe Mode
1. Select your desired session duration
2. Tap the central circle to start
3. Follow the on-screen prompts to breathe
4. Tap "Stop" to end your session early

### Focus Mode
1. Choose between Work, Break, or Long Break
2. Tap the timer circle to start
3. The timer will count down and track your progress
4. Tap to pause/resume, or use Reset to start over

### Sleep Mode
1. Select your desired sleep timer duration
2. Tap the moon to start the countdown
3. Relax as the gentle animations guide you to sleep
4. The timer will automatically stop when complete

---

Built with SwiftUI

