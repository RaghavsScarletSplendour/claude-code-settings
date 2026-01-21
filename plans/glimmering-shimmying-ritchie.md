# Promptr - App Store Readiness Assessment

## Current State Summary

**Promptr** is a **Next.js web application** for prompt management with semantic search. It is **NOT currently a mobile app**.

### Technology Stack
- Next.js 16.1.1 + React 19.2.3 + TypeScript
- Tailwind CSS 4 + Framer Motion
- Supabase (PostgreSQL + pgvector)
- Clerk authentication
- OpenAI API for semantic search

### Mobile Readiness: **0%**
- No React Native, Expo, or Capacitor
- No iOS/Android directories
- No PWA configuration
- No native mobile support whatsoever

---

## App Store Readiness Score: **~20-25%**

### What You HAVE

| Category | Status |
|----------|--------|
| Core features (CRUD, search, categories) | Done |
| User authentication (Clerk) | Done |
| Responsive web design (Tailwind) | Done |
| Security headers configured | Done |
| Basic favicon | Done |
| Polished UI/UX with animations | Done |
| Beta access system | Done |

### What You're MISSING (Critical for App Store)

| Category | Status | Priority |
|----------|--------|----------|
| **Privacy Policy** | Missing | REQUIRED |
| **Terms of Service** | Missing | REQUIRED |
| **Native mobile wrapper** (React Native/Expo) | Missing | REQUIRED |
| **App icons** (1024x1024 + all sizes) | Missing | REQUIRED |
| **App store metadata** (descriptions, screenshots) | Missing | REQUIRED |
| Analytics/crash reporting | Missing | HIGH |
| In-app purchases/subscriptions | Missing | If monetizing |
| Accessibility (ARIA labels) | Partial | REQUIRED |
| Automated tests | Missing | HIGH |
| CI/CD pipeline | Missing | HIGH |

---

## Options to Make This App Store Ready

### Option 1: Expo (Recommended for React)
- Wraps your React/Next.js knowledge
- Can share some component logic
- Managed workflow simplifies iOS/Android builds
- Would require rebuilding UI with React Native components

### Option 2: Capacitor
- Wraps your existing web app as-is
- Minimal code changes
- Native shell around your web view
- Lower performance than true native

### Option 3: React Native
- Full native experience
- Maximum control
- Steeper learning curve than Expo
- Complete UI rebuild required

---

## Recommendation: Capacitor + RevenueCat

Based on your goals (Quick MVP + Subscriptions), here's the fastest path:

### Why Capacitor?
- Wraps your existing Next.js web app with minimal changes
- Your current UI/features work as-is
- Fastest time to App Store

### What You'll Need to Add

**Required for App Store Submission:**
1. Privacy Policy page (can be a simple `/privacy` route)
2. Terms of Service page (`/terms` route)
3. App icons (1024x1024 source, Capacitor generates sizes)
4. App store screenshots (iPhone + iPad)
5. App description/metadata

**For Subscriptions:**
- RevenueCat SDK (works with Capacitor)
- Apple Developer account ($99/yr)
- Google Play Developer account ($25 one-time)
- Configure subscription products in App Store Connect & Play Console

**Nice to Have:**
- Firebase Analytics + Crashlytics
- Push notifications (if needed)

### Estimated Timeline
- **Week 1**: Add legal pages, app icons, Capacitor setup
- **Week 2**: RevenueCat integration, subscription UI
- **Week 3**: Testing, app store metadata, submission

### Next Steps (if you want to proceed)
1. Set up Apple Developer & Google Play accounts
2. I can help you add Capacitor + RevenueCat
3. Create privacy policy & terms of service
4. Generate app icons
5. Build and submit

---

## Action Item

Write this full assessment to `/tasks/app-store-readiness.md` in the project directory.
