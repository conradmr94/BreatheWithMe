#!/usr/bin/env python3
"""
Script to download copyright-free ambient sounds for the BreatheWithMe app.
This script creates placeholder audio files for demonstration purposes.
In a real implementation, you would download actual audio files from sources like:
- freesound.org (requires account)
- pixabay.com
- zapsplat.com

NOTE: This script creates WAV files, not MP3. To convert to MP3, you need:
1. Install: pip install pydub
2. Install ffmpeg: brew install ffmpeg (macOS) or apt-get install ffmpeg (Linux)
3. Run this script, which will create WAV files and convert them to MP3
"""

import os
import numpy as np
import wave
import struct

try:
    from pydub import AudioSegment
    HAS_PYDUB = True
except ImportError:
    HAS_PYDUB = False
    print("⚠️  Warning: pydub not installed. Will create WAV files only.")

def create_placeholder_audio(filename, duration=10, sample_rate=44100):
    """Create a placeholder audio file with simple generated sound"""
    
    # Create WAV file first
    wav_filename = filename.replace('.mp3', '.wav') if filename.endswith('.mp3') else filename
    
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
    elif 'city' in filename.lower():
        # City: traffic and urban ambiance with varied frequencies
        audio = 0.08 * np.sin(2 * np.pi * 1.5 * t) + 0.04 * np.sin(2 * np.pi * 5.0 * t) + 0.03 * np.random.normal(0, 0.02, len(t))
    elif 'fire' in filename.lower():
        # Fire: crackling with noise bursts
        audio = 0.12 * np.random.normal(0, 0.15, len(t)) * np.abs(np.sin(2 * np.pi * 6 * t)) + 0.05 * np.sin(2 * np.pi * 1.5 * t)
    elif 'birds' in filename.lower():
        # Birds: chirping with high frequency modulation
        audio = 0.9 * np.sin(2 * np.pi * 8.0 * t) * np.abs(np.sin(2 * np.pi * 0.3 * t)) + 0.06 * np.sin(2 * np.pi * 12.0 * t) * np.abs(np.sin(2 * np.pi * 0.5 * t))
    else:
        # Default: simple sine wave
        audio = 0.1 * np.sin(2 * np.pi * 440 * t)
    
    # Normalize and convert to 16-bit PCM
    audio = np.clip(audio, -1.0, 1.0)
    audio_int16 = (audio * 32767).astype(np.int16)
    
    # Write WAV file
    with wave.open(wav_filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes per sample
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(audio_int16.tobytes())
    
    # Convert to MP3 if requested and pydub is available
    if filename.endswith('.mp3') and HAS_PYDUB:
        try:
            audio = AudioSegment.from_wav(wav_filename)
            audio.export(filename, format='mp3', bitrate='128k')
            os.remove(wav_filename)  # Clean up WAV file
            return True
        except Exception as e:
            print(f"⚠️  Failed to convert {wav_filename} to MP3: {e}")
            return False
    return True

def main():
    """Download/create ambient sound files"""
    
    # Create audio directory
    audio_dir = "BreatheWithMe/AudioFiles"
    os.makedirs(audio_dir, exist_ok=True)
    
    # List of ambient sounds to create
    sounds = [
        "rain.mp3",
        "ocean.mp3", 
        "wind.mp3",
        "thunder.mp3",
        "forest.mp3",
        "cafe.mp3",
        "city.mp3",
        "fire.mp3",
        "birds.mp3"
    ]
    
    print("🎵 Creating placeholder ambient sound files...")
    
    if not HAS_PYDUB:
        print("⚠️  Creating WAV files only (pydub not installed)")
        print("   To create MP3 files, run: pip install pydub && brew install ffmpeg\n")
    
    for sound in sounds:
        filepath = os.path.join(audio_dir, sound)
        success = create_placeholder_audio(filepath)
        if success:
            print(f"✅ Created {sound}")
        else:
            print(f"⚠️  Created {sound.replace('.mp3', '.wav')} (MP3 conversion failed)")
    
    print(f"\n🎧 All audio files created in {audio_dir}/")
    print("📝 Note: These are placeholder files. For production, replace with real audio files from:")
    print("   - freesound.org (requires free account)")
    print("   - pixabay.com")
    print("   - zapsplat.com")
    print("   - soundbible.com")

if __name__ == "__main__":
    main()
