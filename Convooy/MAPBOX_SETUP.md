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
- **Prebuilt Search UI**: Professional MapBox Search interface
- **Real-time Search**: Live results from MapBox's global database
- **Category Search**: Built-in search categories and suggestions
- **Ready for Navigation**: Foundation set up for turn-by-turn navigation
- **Secure Token Management**: Access token stored in Info.plist as recommended by MapBox

### 5. Search Functionality

The prebuilt search UI includes:
- **Professional Search Interface**: MapBox-designed search experience
- **Real-time Results**: Live search from global location database
- **Category Search**: Built-in search categories
- **Autocomplete**: Smart suggestions as you type
- **User Favorites**: Built-in favorites system
- **Address Formatting**: Professional address display

### 6. Next Steps for Turn-by-Turn Navigation

The current setup provides the foundation for:
- Route planning
- Turn-by-turn directions
- Voice guidance
- Traffic information

### Troubleshooting

- **Build Errors**: Make sure both MapBox Maps and Search packages are properly added
- **Search SDK Download Issues**: Ensure .netrc file is configured with secret token
- **Location Not Working**: Check that location permissions are granted
- **Map Not Loading**: Verify your access token is correct in Info.plist
- **Search Not Working**: Ensure both MapBox packages are added and tokens are valid

## Current App Structure

- **Welcome Tab**: Shows your Convooy logo and branding
- **Map Tab**: MapBox map with prebuilt search UI
  - Full-screen map focused on user's current location
  - Professional MapBox Search interface overlay
  - Ready for destination selection and navigation
- **Location Manager**: Handles GPS permissions and updates
- **MapBox Service**: Manages map configuration and initialization (reads token from Info.plist)
- **Search Service**: Integrates with prebuilt MapBox Search UI components
