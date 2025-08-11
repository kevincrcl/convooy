# MapBox Setup for Convooy

## Adding MapBox Dependencies

To use the MapBox integration in your Convooy app, you need to add the MapBox SDK to your Xcode project:

### 1. Add MapBox Package Dependency

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your target
4. Go to the "Package Dependencies" tab
5. Click the "+" button
6. Enter the MapBox package URL: `https://github.com/mapbox/mapbox-maps-ios`
7. Click "Add Package"
8. Select "MapboxMaps" and click "Add Package"

### 2. Get Your MapBox Access Token

1. Go to [MapBox Account](https://account.mapbox.com/access-tokens/)
2. Sign in or create an account
3. Create a new access token or use the default public token
4. Copy the token

### 3. Update the Access Token in Info.plist

1. Open `Info.plist` in Xcode
2. Find the `MBXAccessToken` key (already added)
3. Replace `YOUR_MAPBOX_ACCESS_TOKEN` with your actual token
4. Build and run the project

**Note**: The app is configured to read the token from `Info.plist` using the `MBXAccessToken` key, which is the recommended approach by MapBox for better security and configuration management.

### 4. Features Included

- **Current Location Focus**: Map automatically centers on user's location
- **Location Permissions**: Handles location access requests
- **2D Location Puck**: Shows user's position and heading on the map
- **Tab Navigation**: Easy switching between welcome screen and map
- **Ready for Navigation**: Foundation set up for turn-by-turn navigation
- **Secure Token Management**: Access token stored in Info.plist as recommended by MapBox

### 5. Next Steps for Turn-by-Turn Navigation

The current setup provides the foundation for:
- Route planning
- Turn-by-turn directions
- Voice guidance
- Traffic information

### Troubleshooting

- **Build Errors**: Make sure MapBox package is properly added
- **Location Not Working**: Check that location permissions are granted
- **Map Not Loading**: Verify your access token is correct in Info.plist
- **Token Error**: Ensure `MBXAccessToken` is properly set in Info.plist

## Current App Structure

- **Welcome Tab**: Shows your Convooy logo and branding
- **Map Tab**: MapBox map focused on user's current location
- **Location Manager**: Handles GPS permissions and updates
- **MapBox Service**: Manages map configuration and initialization (reads token from Info.plist)
