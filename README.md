# iconstruct

Flutter app for the iConstruct authentication and onboarding flow.

## Email Verification Setup

This repo now uses Firebase Authentication's built-in email verification flow.

### 1. Enable Firebase services

1. In the Firebase console, enable Authentication with the Email/Password provider.
2. In Authentication, configure the email verification template if you want custom branding.

### 2. Run the app

```bash
flutter pub get
flutter run
```

The app will create users with Firebase Authentication, send Firebase's built-in verification email, and prompt users to refresh their verification status after tapping the email link.
