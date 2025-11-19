# Operations Center Setup Guide

## CRITICAL: Link xcconfig Files to Xcode Project

**The xcconfig files exist but are NOT linked to the Xcode project.** You MUST complete this manual step before the app will work on physical devices.

### Required Steps (5 minutes):

1. **Open the project in Xcode**
   ```bash
   open "apps/Operations Center/Operations Center.xcodeproj"
   ```

2. **Select the PROJECT (not target)**
   - In Project Navigator (⌘1), click "Operations Center" at the very top (blue icon)
   - This opens project settings, NOT target settings

3. **Go to Info tab**
   - You'll see "Configurations" section with Debug and Release rows

4. **Link xcconfig files**:
   - **Debug row:**
     - Click dropdown under "Operations Center" column
     - Select **"Configs/Development"**

   - **Release row:**
     - Click dropdown under "Operations Center" column
     - Select **"Configs/Production"**

5. **Verify**:
   - Info tab should show:
     - Debug → Configs/Development
     - Release → Configs/Production

6. **Clean and rebuild**:
   ```bash
   cd "apps/Operations Center"
   xcodebuild clean -scheme "Operations Center" -quiet
   xcodebuild build -scheme "Operations Center" -destination 'generic/platform=iOS' -quiet
   ```

7. **Test on iPhone** - Should connect to Supabase successfully

---

## Why This is Required

Xcode needs `baseConfigurationReference` entries in project.pbxproj to read xcconfig files. These can't be safely text-edited—they require UUID generation and multi-section updates. The GUI handles this automatically.

Without linking:
- ❌ xcconfig files are ignored during build
- ❌ `INFOPLIST_KEY_*` settings never populate
- ❌ Info.plist has no values
- ❌ App crashes with "Missing required configuration: SUPABASE_URL"

With linking:
- ✅ Xcode reads xcconfig during build
- ✅ Populates `INFOPLIST_KEY_*` build settings
- ✅ Auto-generates Info.plist with values
- ✅ Available via `Bundle.main.infoDictionary` at runtime

---

## Troubleshooting

### Issue: Dropdown shows "None" for xcconfig files

**Cause:** Xcconfig files not added to project structure

**Fix:**
1. Right-click "Operations Center" project in navigator
2. "Add Files to 'Operations Center'..."
3. Navigate to `Configs/` folder
4. Select Development.xcconfig and Production.xcconfig
5. **Uncheck** "Copy items if needed"
6. **Check** "Create groups" (not folder references)
7. Click Add
8. Retry linking steps

### Issue: "A server with the specified hostname could not be found"

**Causes:**
1. xcconfig not linked (most common)
2. Network connectivity (test URL in Safari)
3. URL syntax error (already fixed—see commit history)

**Fix:** Complete linking steps above

### Issue: App crashes with "Missing required configuration"

**Cause:** xcconfig linked but values not reaching runtime

**Debug:**
Add to `Config.swift`:
```swift
static func debugPrintAllConfig() {
    print("=== Bundle.main.infoDictionary ===")
    if let dict = Bundle.main.infoDictionary {
        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            if key.contains("SUPABASE") || key.contains("FASTAPI") {
                print("\(key) = \(value)")
            }
        }
    }
}
```

Call in `OperationsCenterApp.init()`:
```swift
init() {
    #if DEBUG
    Config.debugPrintAllConfig()
    #endif
}
```

**Expected output after linking:**
```
SUPABASE_URL = https://nfyrtinbdlbwrwrynuwe.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
FASTAPI_URL = https://operations-center.vercel.app
```

---

## Configuration Overview

The app uses xcconfig files for build-time configuration:

- **Development.xcconfig** - Debug builds
- **Production.xcconfig** - Release builds (App Store, TestFlight)

Both files define:
- `INFOPLIST_KEY_SUPABASE_URL` - Supabase project URL
- `INFOPLIST_KEY_SUPABASE_ANON_KEY` - Anonymous key for client access
- `INFOPLIST_KEY_FASTAPI_URL` - FastAPI intelligence endpoint

Values are read at runtime via:
```swift
Bundle.main.infoDictionary?["SUPABASE_URL"]
```

---

## Recent Fixes

**URL Syntax Error (Fixed):**
- ❌ `INFOPLIST_KEY_SUPABASE_URL = https:/$()/nfyrtinbdlbwrwrynuwe.supabase.co`
- ✅ `INFOPLIST_KEY_SUPABASE_URL = https://nfyrtinbdlbwrwrynuwe.supabase.co`

The `$()` syntax means "substitute empty variable" in xcconfig, creating malformed URLs. This has been corrected in both Development.xcconfig and Production.xcconfig.

---

## Alternative: Environment Variables (Simulator Only)

Xcode scheme environment variables work on simulators but NOT physical devices:

1. Product > Scheme > Edit Scheme
2. Run > Arguments > Environment Variables
3. Add SUPABASE_URL, SUPABASE_ANON_KEY, FASTAPI_URL

**Use xcconfig for production.** Environment variables are unreliable on devices.

---

## Security Notes

- xcconfig files contain API keys (anon key is public-safe)
- Never commit service role keys
- Production builds should use same credentials (currently identical)
- Consider separate Supabase projects for dev/prod in future

---

**Once xcconfig files are linked in Xcode, physical device builds will work. Don't skip this step.**
