# iconstruct

Flutter app for the iConstruct authentication and onboarding flow.

## Email OTP Setup

This repo uses a custom 6-digit email OTP flow backed by Firebase Functions, Firestore, and Nodemailer SMTP.

### 1. Enable Firebase services

1. In the Firebase console, enable Authentication with the Email/Password provider.
2. Create a Firestore database in Native mode.
3. Configure the Functions backend parameters and secret for SMTP mail delivery:
	- `EMAIL_FROM`
	- `SMTP_HOST`
	- `SMTP_PORT`
	- `SMTP_USER`
	- `SMTP_PASS`

### 2. Run the app

```bash
flutter pub get
flutter run
```

The app lets the user request a 6-digit OTP from the registration screen, stores the OTP in the `email_otp` collection for 5 minutes, emails the code through Nodemailer SMTP, and requires OTP verification before the registration request is allowed to complete.
