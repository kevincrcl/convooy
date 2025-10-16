# Convooy

A trip planning application with web, iOS, and backend API implementations.

## Project Structure

- `backend/` - Node.js/TypeScript API with PostgreSQL
- `web/` - React/TypeScript web application with Mapbox integration
- `Convooy/` - SwiftUI iOS application with MapKit integration
- `landing-page/` - Marketing landing page

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

## Backend API

The backend provides a REST API with real-time WebSocket support for trip sharing:

- Trip management with share codes
- Stop management and reordering
- Real-time updates via WebSockets
- Comprehensive test suite (104 tests, 80%+ coverage)
- Automatic CI/CD testing

### Setup

```bash
cd backend
yarn install
yarn dev  # Automatically starts database and dev server
yarn test # Run test suite
```

See [backend/README.md](backend/README.md) for detailed documentation.

## Development

All components are being developed to provide the same core functionality:

- Trip creation and management
- Stop management with drag-and-drop reordering
- Route planning and visualization
- Location search and autocomplete
- Real-time location tracking

## CI/CD

- **Backend Tests**: Automatically run on PRs and merges to `main`
  - 104 tests with 80%+ coverage
  - PostgreSQL integration tests
  - Unit tests for business logic
  
See [.github/workflows/README.md](.github/workflows/README.md) for details. 