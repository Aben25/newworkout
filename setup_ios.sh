#!/bin/bash

echo "Setting up iOS development environment..."

# Set Xcode command line tools path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Run Xcode first launch setup
sudo xcodebuild -runFirstLaunch

# Accept Xcode license
sudo xcodebuild -license accept

# Install iOS simulators (optional but recommended)
echo "Installing iOS simulators..."
xcodebuild -downloadPlatform iOS

echo "Setup complete! Run 'flutter doctor' to verify."