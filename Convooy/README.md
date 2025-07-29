# Convooy (Swift)

A trip planning app built with SwiftUI and MapKit.

## Features

- Interactive map with MapKit
- Location services integration
- Trip planning and management
- Stop management

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.0+

## Setup

1. Open `Convooy.xcodeproj` in Xcode
2. Build and run the project
3. Grant location permissions when prompted

## Project Structure

```
Sources/
├── Convooy/
│   └── App.swift                 # Main app entry point
├── Views/
│   └── ContentView.swift         # Main view with map
├── Models/
│   └── Trip.swift               # Trip and stop models
├── Services/
│   └── LocationService.swift    # Location management
└── Utils/                       # Utility functions
```

## Development

This is a bare-bones implementation that will be gradually enhanced to match the functionality of the web version. The current structure provides:

- Basic MapKit integration
- Location services
- Trip data models
- SwiftUI-based UI

## Next Steps

- Add trip creation interface
- Implement stop management
- Add route planning
- Create trip list view
- Add search functionality 