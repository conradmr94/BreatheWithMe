#!/usr/bin/env python3
"""
Script to download copyright-free ambient sounds for the BreatheWithMe app.
This script creates placeholder audio files for demonstration purposes.
In a real implementation, you would download actual audio files from sources like:
- freesound.org (requires account)
- pixabay.com
- zapsplat.com
"""

import os
import numpy as np
import wave
import struct

def create_placeholder_audio(filename, duration=10, sample_rate=44100):
    """Create a placeholder audio file with simple generated sound"""
    
    # Generate simple audio data
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    
    if 'rain' in filename.lower():
        # Rain-like sound: high frequency noise with some modulation
        audio = np.random.normal(0, 0.1, len(t)) * np.sin(2 * np.pi * 8 * t)
    elif 'ocean' in filename.lower():
        # Ocean waves: low frequency sine waves
        audio = 0.3 * np.sin(2 * np.pi * 0.5 * t) + 0.1 * np.sin(2 * np.pi * 1.0 * t)
    elif 'wind' in filename.lower():
        # Wind: filtered noise
        audio = np.random.normal(0, 0.1, len(t)) * np.sin(2 * np.pi * 0.3 * t)
    elif 'thunder' in filename.lower():
        # Thunder: low frequency rumble
        audio = 0.2 * np.sin(2 * np.pi * 0.1 * t) + 0.1 * np.random.normal(0, 0.05, len(t))
    elif 'forest' in filename.lower():
        # Forest: gentle nature sounds
        audio = 0.1 * np.sin(2 * np.pi * 0.4 * t) + 0.05 * np.sin(2 * np.pi * 2.0 * t)
    elif 'cafe' in filename.lower():
        # Cafe: background chatter simulation
        audio = 0.05 * np.sin(2 * np.pi * 3.0 * t) + 0.02 * np.random.normal(0, 0.01, len(t))
    elif 'fan' in filename.lower():
        # Fan: consistent hum
        audio = 0.1 * np.sin(2 * np.pi * 2.0 * t) + 0.05 * np.sin(2 * np.pi * 4.0 * t)
    else:
        # Default: simple sine wave
        audio = 0.1 * np.sin(2 * np.pi * 440 * t)
    
    # Normalize and convert to 16-bit PCM
    audio = np.clip(audio, -1.0, 1.0)
    audio_int16 = (audio * 32767).astype(np.int16)
    
    # Write WAV file
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes per sample
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(audio_int16.tobytes())

def main():
    """Download/create ambient sound files"""
    
    # Create audio directory
    audio_dir = "BreatheWithMe/AudioFiles"
    os.makedirs(audio_dir, exist_ok=True)
    
    # List of ambient sounds to create
    sounds = [
        "rain.wav",
        "ocean.wav", 
        "wind.wav",
        "thunder.wav",
        "forest.wav",
        "cafe.wav",
        "fan.wav"
    ]
    
    print("🎵 Creating placeholder ambient sound files...")
    
    for sound in sounds:
        filepath = os.path.join(audio_dir, sound)
        create_placeholder_audio(filepath)
        print(f"✅ Created {sound}")
    
    print(f"\n🎧 All audio files created in {audio_dir}/")
    print("📝 Note: These are placeholder files. For production, replace with real audio files from:")
    print("   - freesound.org (requires free account)")
    print("   - pixabay.com")
    print("   - zapsplat.com")
    print("   - soundbible.com")

if __name__ == "__main__":
    main()
