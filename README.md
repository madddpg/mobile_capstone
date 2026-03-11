# iconstruct

Flutter app for the iConstruct authentication and onboarding flow.

## Email OTP Setup

This repo now expects real email OTP delivery through Firebase Functions and Gmail SMTP.

### 1. Enable Firebase services

1. In the Firebase console, enable Authentication with the Email/Password provider.
2. Create a Firestore database in Native mode.
3. Make sure your project is on the Blaze plan because Cloud Functions outbound email requires billing.

### 2. Install Functions dependencies

From the project root:

```bash
cd functions
npm install
```

### 3. Set Firebase Functions parameters and secrets

Use Gmail SMTP with an App Password from the Google account that will send OTP emails.

Create [functions/.env.example](functions/.env.example) as a template, then create your real environment file as `functions/.env.iconstruct-58a87`.

Example `functions/.env.iconstruct-58a87`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_FROM_EMAIL=yourgmailaddress@gmail.com
SMTP_FROM_NAME=iConstruct
```

```bash
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASS
firebase deploy --only functions
```

The deploy reads the non-secret params from `functions/.env.iconstruct-58a87` and the secrets from Firebase Secret Manager.

### 4. Gmail requirements

1. Turn on 2-Step Verification for the Gmail account.
2. Generate a Google App Password.
3. Use the Gmail address as `SMTP_USER` and the App Password as `SMTP_PASS`.

### 5. Deploy and test

```bash
firebase deploy --only functions
flutter pub get
flutter run
```

The app will create users with Firebase Authentication, send a 6-digit OTP by email using Cloud Functions, and verify the OTP before treating the account as verified.
