# Security Configuration Setup Guide

This guide will help you configure the secure API keys and secrets for your Animarc iOS app.

## ✅ What Was Changed

All hardcoded secrets have been moved from source code to Xcode build settings:
- ✅ Supabase URL and Anonymous Key
- ✅ Google OAuth Client ID  
- ✅ RevenueCat API Key
- ✅ Added authorization checks to portal progress updates

## 🔧 Step-by-Step Setup Instructions

### 1. Open Your Xcode Project

1. Open `Animarc IOS.xcodeproj` in Xcode
2. Select the **Animarc IOS** project in the Project Navigator (top item)
3. Select the **Animarc IOS** target (under TARGETS)
4. Click on the **Build Settings** tab

### 2. Add User-Defined Build Settings

1. In the Build Settings search bar, type "User-Defined" or look for the section
2. Click the **+** button at the top of the Build Settings panel
3. Select **Add User-Defined Setting**

4. Add these 4 settings one by one:

#### Setting 1: SUPABASE_URL
- **Name:** `SUPABASE_URL`
- **Value:** `https://girifmitgbaxiaktjckz.supabase.co`

#### Setting 2: SUPABASE_ANON_KEY
- **Name:** `SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdpcmlmbWl0Z2JheGlha3RqY2t6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5MTc0MDEsImV4cCI6MjA3NTQ5MzQwMX0.XDMQp7h_WaP1OwGSfn8lPksvRjFq5KiQoySf2VPTyPo`

#### Setting 3: GOOGLE_CLIENT_ID
- **Name:** `GOOGLE_CLIENT_ID`
- **Value:** `443436294835-qgd6v7m2nov13rl2624eala6inr0scp1.apps.googleusercontent.com`

#### Setting 4: REVENUECAT_API_KEY
- **Name:** `REVENUECAT_API_KEY`
- **Value:** `appl_OCBzZIPDsWduwvkbMGWGizCBIzF`

### 3. Configure Info.plist Processing

The Info.plist file has been updated to reference these build settings. Xcode will automatically substitute the values during build.

**Note:** The Info.plist already contains the placeholders:
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
<key>GOOGLE_CLIENT_ID</key>
<string>$(GOOGLE_CLIENT_ID)</string>
<key>REVENUECAT_API_KEY</key>
<string>$(REVENUECAT_API_KEY)</string>
```

### 4. Verify Configuration

1. Build the project (⌘+B)
2. If configuration is missing, you'll get a clear error message indicating which key is missing
3. The app will validate configuration on startup in DEBUG mode

### 5. Test the App

Run the app and verify:
- ✅ App launches without errors
- ✅ Supabase connection works
- ✅ Google Sign-In works
- ✅ RevenueCat subscription checks work
- ✅ Portal raids work correctly

## 🔒 Security Benefits

1. **Secrets Not in Source Code**: API keys are no longer hardcoded in Swift files
2. **Not in Git**: Build settings with secrets won't be committed to git (they're in `.xcuserdata`)
3. **Per-Developer**: Each developer can have their own build settings
4. **Environment-Specific**: You can have different values for Debug vs Release builds

## 📝 Important Notes

- **Build Settings are Per-User**: These settings are stored in `xcuserdata/` which should be in `.gitignore`
- **Team Sharing**: For team members, share these values securely (password manager, encrypted message, etc.)
- **CI/CD**: For automated builds, set these as environment variables in your CI/CD system
- **Production**: Consider using different keys for production vs development

## 🚨 Troubleshooting

### Error: "SUPABASE_URL must be set in build settings"
- Make sure you added the User-Defined Setting correctly
- Check that the setting name matches exactly (case-sensitive)
- Try cleaning the build folder (Product → Clean Build Folder)

### Error: "Value is empty"
- Make sure you entered the full value (no extra spaces)
- Check that the value wasn't truncated

### App crashes on launch
- Check the console for which specific key is missing
- Verify all 4 User-Defined Settings are added
- Make sure Info.plist has the correct keys

## ✅ Verification Checklist

- [ ] All 4 User-Defined Settings added in Build Settings
- [ ] Info.plist contains the 4 configuration keys
- [ ] Project builds successfully
- [ ] App launches without configuration errors
- [ ] Supabase authentication works
- [ ] Google Sign-In works
- [ ] RevenueCat works
- [ ] Portal raids work correctly

## 🔄 Next Steps

1. **Remove old secrets from git history** (if already committed):
   ```bash
   # Use git-filter-repo or BFG Repo-Cleaner to remove secrets from history
   # Or simply ensure they're not in future commits
   ```

2. **Add to .gitignore** (if not already):
   ```
   xcuserdata/
   *.xcuserstate
   ```

3. **Share securely with team**: Use a password manager or secure channel to share the API key values with team members

4. **Set up CI/CD**: Configure your CI/CD pipeline to inject these values as environment variables

---

**Security Status**: ✅ All hardcoded secrets have been removed from source code and moved to secure build settings.

