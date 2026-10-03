# SavingsManager

iOS app for tracking savings using NFC cards.

## Requirements
- iOS 18.0+
- Xcode 16+
- Physical iPhone with NFC (required for testing)

## Features
- Read/write NFC NDEF tags for savings cards
- Track deposits and withdrawals
- Transaction history
- Local-only storage with SwiftData
- Export/import data as JSON

## Setup
1. Open `SavingsManager.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Enable "Near Field Communication Tag Reading" capability
4. Build and run on physical device (NFC doesn't work in simulator)

## NFC Card Format
The app uses NDEF format with:
- URI record: `savings://card?balance=X&currency=USD`
- JSON record: `application/json` with balance, currency, updated, uid

## Project Structure
```
SavingsManager/
├── App/                    # App entry point
├── Models/                 # SwiftData models
├── Services/               # NFC, parsing, persistence
├── Views/                  # SwiftUI views
├── Components/             # Reusable UI components
├── Utilities/              # Formatters, helpers
└── Resources/              # Assets, Info.plist, entitlements
```

## Testing NFC
1. Use blank NDEF-formatted cards (NTAG213/215/216, etc.)
2. First scan creates the card in app
3. Subsequent scans read existing balance
4. Write saves updated balance back to card