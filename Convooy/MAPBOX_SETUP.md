# MapBox Setup for Convooy

## Adding MapBox Dependencies

To use the MapBox integration in your Convooy app, you need to add the MapBox SDK to your Xcode project:

### 1. Add MapBox Package Dependencies

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your target
4. Go to the "Package Dependencies" tab
5. Click the "+" button
6. Enter the MapBox Maps package URL: `https://github.com/mapbox/mapbox-maps-ios`
7. Click "Add Package"
8. Select "MapboxMaps" and click "Add Package"
9. **IMPORTANT**: Also add the MapBox Search package: `https://github.com/mapbox/search-ios.git`
10. Select **MapboxSearchUI** (for prebuilt UI components) and click "Add Package"
11. Set version to **Exact** and enter `2.14.1`
12. **NAVIGATION**: Add the MapBox Navigation SDK v3: `https://github.com/mapbox/mapbox-navigation-ios`
13. Select **MapboxNavigation** and click "Add Package"
14. **IMPORTANT**: Make sure to select both **MapboxNavigationCore** and **MapboxNavigationUIKit** when adding the package

### 2. Configure Credentials (Required for Search SDK)

The MapBox Search SDK requires additional setup:

#### Step 1: Create a Secret Token
1. Go to [MapBox Account](https://account.mapbox.com/access-tokens/)
2. Create a new token with `Downloads:Read` scope enabled
3. This is a **secret token** - copy it immediately

#### Step 2: Configure .netrc File
1. In Terminal, go to your home directory: `cd ~`
2. Create .netrc file: `touch .netrc`
3. Open it: `open .netrc`
4. Add these lines (replace with your secret token):
   ```
   machine api.mapbox.com
   login mapbox
   password YOUR_SECRET_TOKEN
   ```
5. Set permissions: `chmod -R 0600 .netrc`

### 3. Configure Public Access Token

1. Open your project's `Info.plist` file
2. Add key `MBXAccessToken` with your public access token value
3. This is the same token you use for Maps

### 4. Features Included

- **Current Location Focus**: Map automatically centers on user's location
- **Location Permissions**: Handles location access requests
- **2D Location Puck**: Shows user's position on the map
- **Tab Navigation**: Easy switching between welcome screen and map
- **Custom Search UI**: Professional search interface with PlaceAutocomplete
- **Real-time Search**: Live results from MapBox's global database
- **Professional Navigation**: Turn-by-turn navigation with Navigation SDK v3
- **Route Rendering**: Professional route lines and navigation UI
- **Voice Instructions**: Built-in voice guidance
- **Traffic Avoidance**: Real-time traffic and incident avoidance
- **Offline Support**: Offline routing capabilities
- **Secure Token Management**: Access token stored in Info.plist as recommended by MapBox

### 5. Search Functionality

The custom search UI includes:
- **Professional Search Interface**: Custom search bar with autocomplete
- **Real-time Results**: Live search from global location database
- **Location Proximity**: Results based on your current location
- **POI Filtering**: Focuses on places you can navigate to
- **Address Formatting**: Professional address display

### 6. Navigation Functionality

The Navigation SDK v3 provides:
- **Turn-by-Turn Navigation**: Professional navigation experience
- **Voice Instructions**: Audio guidance during navigation
- **Route Rendering**: Beautiful route lines and navigation UI
- **Traffic Avoidance**: Real-time traffic and incident avoidance
- **Alternative Routes**: Multiple route options
- **Offline Support**: Navigation without internet connection
- **Navigation Camera**: Automatic camera controls during navigation
- **Rerouting**: Automatic route recalculation

### 7. Requirements

- **Swift 5.9+**: Required for Navigation SDK v3
- **Xcode 15.0+**: Required for Navigation SDK v3
- **iOS 14.0+**: Minimum iOS version supported

### 8. Package Structure

The MapBox Navigation SDK v3 includes:
- **MapboxNavigationCore**: Core navigation functionality and types
- **MapboxNavigationUIKit**: UI components for navigation interface
- **MapboxDirections**: Route calculation and waypoint management

### Troubleshooting

- **Build Errors**: Make sure all MapBox packages are properly added
- **Search SDK Download Issues**: Ensure .netrc file is configured with secret token
- **Location Not Working**: Check that location permissions are granted
- **Map Not Loading**: Verify your access token is correct in Info.plist
- **Search Not Working**: Ensure both MapBox packages are added and tokens are valid
- **Navigation Not Working**: Make sure MapBox Navigation SDK v3 package is added with both Core and UIKit modules
- **Version Compatibility**: Ensure you're using Swift 5.9+ and Xcode 15.0+
- **Module Import Issues**: Use `import MapboxNavigationCore` and `import MapboxNavigationUIKit`

## Current App Structure

- **Welcome Tab**: Shows your Convooy logo and branding
- **Map Tab**: MapBox map with search and navigation functionality
  - Full-screen map focused on user's current location
  - Custom search interface with PlaceAutocomplete
  - Professional navigation with Navigation SDK v3
  - Turn-by-turn directions with voice guidance
- **Location Manager**: Handles GPS permissions and updates
- **MapBox Service**: Manages map configuration and initialization (reads token from Info.plist)
- **Search Service**: Integrates with custom search UI and triggers navigation
- **Navigation Service**: Professional navigation using Navigation SDK v3
