# Convooy

A trip planning application with both web and iOS implementations.

## Project Structure

- `web/` - React/TypeScript web application with Mapbox integration
- `Convooy/` - SwiftUI iOS application with MapKit integration

## Web Version

The web version is built with React, TypeScript, and Mapbox. It provides:

- Interactive map with Mapbox
- Location search and autocomplete
- Trip planning with draggable stops
- Real-time route visualization

### Setup

```bash
cd web
yarn install
yarn dev
```

## iOS Version

The iOS version is built with SwiftUI and MapKit. It provides:

- Native iOS map experience
- Location services integration
- Trip planning and management
- Native iOS UI/UX

### Setup

1. Open `Convooy/Convooy.xcodeproj` in Xcode
2. Build and run the project
3. Grant location permissions when prompted

## Development

Both versions are being developed in parallel to provide the same core functionality:

- Trip creation and management
- Stop management with drag-and-drop reordering
- Route planning and visualization
- Location search and autocomplete
- Real-time location tracking

The iOS version is currently in early development and will gradually match the functionality of the web version. 