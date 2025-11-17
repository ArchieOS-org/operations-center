# Operations Center Setup Guide

## Configuration

The app requires environment configuration before it can run.

### Option 1: Xcode Scheme Environment Variables (Recommended for Development)

1. Open `Operations Center.xcodeproj` in Xcode
2. Select **Product > Scheme > Edit Scheme...**
3. Select **Run** in the sidebar
4. Select the **Arguments** tab
5. Under **Environment Variables**, add:
   - `SUPABASE_URL` = `https://your-project.supabase.co`
   - `SUPABASE_ANON_KEY` = `your-anon-key-here`
   - `FASTAPI_URL` = `https://your-project.vercel.app` (optional)

### Option 2: Info.plist (For Production Builds)

Add the following keys to your `Info.plist`:

```xml
<key>SUPABASE_URL</key>
<string>https://your-project.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your-anon-key-here</string>
<key>FASTAPI_URL</key>
<string>https://your-project.vercel.app</string>
```

**IMPORTANT:** Add `Info.plist` to `.gitignore` if it contains secrets.

### Option 3: .xcconfig Files (Best for Team Projects)

1. Create `Config.xcconfig`:
   ```env
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key-here
   FASTAPI_URL = https://your-project.vercel.app
   ```

2. Add `Config.xcconfig` to `.gitignore`
3. Create `Config.xcconfig.example` as a template
4. In Xcode project settings, set **Configurations** to use `Config.xcconfig`

## Validation

The app validates configuration on launch:
- **Development:** Fails with `fatalError` if configuration is missing/invalid
- **Production:** Logs error and attempts graceful degradation

Check console output for:
- `✅ Configuration validated successfully`
- `⚠️ Configuration error: ...`

## Security Notes

- **NEVER commit secrets to git**
- Use environment variables for local development
- Use Info.plist or .xcconfig for production builds
- Add sensitive files to `.gitignore`:
  - `.env`
  - `Config.xcconfig`
  - `Info.plist` (if it contains secrets)
