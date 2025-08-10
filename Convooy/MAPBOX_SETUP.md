# MapBox Integration Setup Guide

## 🔐 **Token Security & Configuration**

### **Method 1: Environment Variables (Most Secure - Recommended)**

#### **Option A: Set in Xcode Scheme**
1. **Open your project** in Xcode
2. **Select your scheme** (Convooy) from the toolbar
3. **Click "Edit Scheme"** (or press Cmd+<)
4. **Select "Run"** from the left sidebar
5. **Go to "Arguments" tab**
6. **Under "Environment Variables"**, click the **+** button
7. **Add:**
   - **Name:** `MAPBOX_ACCESS_TOKEN`
   - **Value:** `your_actual_token_here`
8. **Click "Close"**

#### **Option B: Set in Terminal (Current Session)**
```bash
export MAPBOX_ACCESS_TOKEN="your_actual_token_here"
open Convooy.xcodeproj
```

#### **Option C: Add to Shell Profile (Permanent)**
```bash
# Add to ~/.zshrc, ~/.bash_profile, etc.
echo 'export MAPBOX_ACCESS_TOKEN="your_actual_token_here"' >> ~/.zshrc
source ~/.zshrc
```

### **Method 2: Configuration File (Development Only)**

1. **Copy the template:**
   ```bash
   cp Sources/Config/MapBoxConfig.template.swift Sources/Config/MapBoxConfig.swift
   ```

2. **Edit the file** and replace `"your_development_token_here"` with your actual token

3. **⚠️ Important:** This file is in `.gitignore` to prevent committing secrets

## 🚀 **Phase 1: SDK Integration (Current)**

### **What's Already Done:**
✅ Project configuration updated  
✅ MapBox service created  
✅ Map view component ready  
✅ **NEW:** Secure token configuration system  
✅ **NEW:** Token validation and masking  
✅ **NEW:** Development vs production handling  

### **Next Steps:**

#### **1. Get MapBox Access Token**
1. Go to [MapBox Account](https://account.mapbox.com/)
2. Sign up or log in
3. Navigate to "Access Tokens"
4. Create a new token or copy your default public token
5. **Keep this token secure!**

#### **2. Configure Token (Choose one method above)**

#### **3. Add MapBox SDK to Project**
1. Open Xcode project
2. Go to File → Add Package Dependencies
3. Enter URL: `https://github.com/mapbox/mapbox-maps-ios`
4. Select version: `10.0.0` or latest stable
5. Add to your main target

#### **4. Test Configuration**
The app will now show:
- ✅ **SDK Ready** if token is valid
- ❌ **Invalid Token** if token is missing/invalid
- 🔒 **Masked token** (e.g., "pk.ey...abc123") for security

## 🗺️ **Phase 2: Map Implementation (Next)**

### **Planned Features:**
- [ ] Real MapBox map display
- [ ] Current location marker
- [ ] Map controls and gestures
- [ ] Zoom and pan functionality

### **Files to Update:**
- `MapBoxMapView.swift` - Replace placeholder with real map
- `MapBoxService.swift` - Add map configuration

## 🔍 **Phase 3: Search & Routing (Future)**

### **Planned Features:**
- [ ] MapBox Geocoding API integration
- [ ] Real-time search suggestions
- [ ] Route calculation with MapBox Directions
- [ ] Route visualization on map

### **Files to Update:**
- `LocationSearchService.swift` - Replace with MapBox search
- `RouteService.swift` - Replace with MapBox routing

## 🧭 **Phase 4: Navigation (Future)**

### **Planned Features:**
- [ ] Turn-by-turn navigation
- [ ] Voice guidance
- [ ] Navigation UI controls
- [ ] Route progress tracking

## 🛠️ **Development Commands**

### **Regenerate Xcode Project:**
```bash
xcodegen generate
```

### **Build and Run:**
```bash
# Make sure environment variable is set
export MAPBOX_ACCESS_TOKEN="your_token_here"
xcodebuild -project Convooy.xcodeproj -scheme Convooy -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 📱 **Testing**

### **Current Status:**
- ✅ App builds without errors
- ✅ Placeholder map displays
- ✅ Location services work
- ✅ Search UI ready
- ✅ **NEW:** Token validation system
- ⏳ MapBox SDK integration pending

### **Token Validation Test:**
After setting your token, you should see:
- ✅ **SDK Ready** status
- 🔒 **Masked token** display
- **No red error messages**

## 🔧 **Troubleshooting**

### **Common Issues:**
1. **"Invalid Token" error**
   - Check environment variable is set correctly
   - Restart Xcode after setting environment variable
   - Verify token format (should start with `pk.ey`)

2. **Build errors after SDK addition**
   - Clean build folder (Cmd+Shift+K)
   - Check SDK version compatibility

3. **Map not displaying**
   - Verify access token is valid
   - Check network permissions
   - Ensure token has proper scopes

### **Security Best Practices:**
- ✅ **Never commit tokens** to git
- ✅ **Use environment variables** for CI/CD
- ✅ **Rotate tokens** regularly
- ✅ **Limit token scopes** to minimum required
- ✅ **Use different tokens** for development/production

## 📚 **Resources**

- [MapBox iOS SDK Documentation](https://docs.mapbox.com/ios/maps/)
- [MapBox Access Tokens](https://docs.mapbox.com/help/glossary/access-token/)
- [MapBox Styles](https://docs.mapbox.com/api/maps/styles/)
- [MapBox Directions API](https://docs.mapbox.com/api/navigation/directions/)
- [Environment Variables in Xcode](https://developer.apple.com/documentation/xcode/environment-variables) 