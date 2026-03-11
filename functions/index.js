const crypto = require("crypto");
const admin = require("firebase-admin");
const {Resend} = require("resend");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const EMAIL_FROM = defineString("EMAIL_FROM", {
  default: "iConstruct <onboarding@resend.dev>",
});
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  return request.auth.uid;
}

function readEmail(request) {
  const email = String(request.data?.email || "").trim().toLowerCase();
  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required.");
  }
  return email;
}

function readOtp(request) {
  const otp = String(request.data?.otp || "").trim();
  if (!/^\d{6}$/.test(otp)) {
    throw new HttpsError("invalid-argument", "Enter the 6-digit OTP code.");
  }
  return otp;
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function hashOtp(uid, otp) {
  return crypto.createHash("sha256").update(`${uid}:${otp}`).digest("hex");
}

function buildResendClient() {
  return new Resend(RESEND_API_KEY.value());
}

function mapEmailProviderError(error) {
  const message = String(error?.message || error?.response || "");

  if (
    error?.statusCode === 401 ||
    error?.statusCode === 403 ||
    message.toLowerCase().includes("api key")
  ) {
    return new HttpsError(
      "failed-precondition",
      "Email delivery is not configured correctly. Check the Resend API key and sender address in Firebase Functions config.",
    );
  }

  if (
    error?.statusCode === 429 ||
    message.toLowerCase().includes("rate limit")
  ) {
    return new HttpsError(
      "resource-exhausted",
      "The email provider rate limit has been reached. Please wait and try again later.",
    );
  }

  if (message.toLowerCase().includes("verify a domain")) {
    const allowedRecipient = message.match(/own email address \(([^)]+)\)/)?.[1];

    return new HttpsError(
      "failed-precondition",
      allowedRecipient
        ? `Resend is still in testing mode and can only send to ${allowedRecipient}. Verify a domain in Resend and update EMAIL_FROM, or test with that recipient.`
        : "The email sender is not ready yet. Verify your sending domain in Resend and update EMAIL_FROM before sending to other recipients.",
    );
  }

  return new HttpsError(
    "internal",
    "Could not send the verification email right now. Please try again later.",
  );
}

function otpEmailHtml(otp) {
  return `
    <div style="font-family: Arial, sans-serif; background: #f4f0e8; padding: 24px; color: #243749;">
      <div style="max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 20px; padding: 28px;">
        <p style="margin: 0 0 10px; font-size: 14px; color: #5a6978;">iConstruct Email Verification</p>
        <h2 style="margin: 0 0 14px; font-size: 28px;">Your OTP Code</h2>
        <p style="margin: 0 0 20px; font-size: 14px; line-height: 1.5;">Enter this 6-digit code in the app to verify your account.</p>
        <div style="font-size: 34px; letter-spacing: 10px; font-weight: 700; background: #f1e6d4; border-radius: 16px; padding: 18px; text-align: center;">${otp}</div>
        <p style="margin: 20px 0 0; font-size: 13px; color: #5a6978;">This code expires in 10 minutes.</p>
      </div>
    </div>
  `;
}

async function loadVerifiedUser(uid, email) {
  const userRecord = await auth.getUser(uid);
  if ((userRecord.email || "").toLowerCase() !== email) {
    throw new HttpsError(
      "permission-denied",
      "OTP can only be used for the signed-in account email.",
    );
  }
  return userRecord;
}

exports.sendEmailOtp = onCall(
  {secrets: [RESEND_API_KEY]},
  async (request) => {
    const uid = requireAuth(request);
    const email = readEmail(request);
    const userRecord = await loadVerifiedUser(uid, email);

    if (userRecord.emailVerified) {
      return {
        success: true,
        message: "This email is already verified.",
      };
    }

    const docRef = db.collection("emailOtps").doc(uid);
    const existingDoc = await docRef.get();
    const existingData = existingDoc.data();
    const now = Date.now();

    if (existingData?.createdAt?.toMillis) {
      const createdAt = existingData.createdAt.toMillis();
      if (now - createdAt < RESEND_COOLDOWN_MS) {
        throw new HttpsError(
          "resource-exhausted",
          "Please wait before requesting another OTP.",
        );
      }
    }

    const otp = generateOtp();
    const expiresAt = admin.firestore.Timestamp.fromMillis(now + OTP_TTL_MS);

    await docRef.set({
      email,
      codeHash: hashOtp(uid, otp),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt,
      attempts: 0,
      verifiedAt: null,
    }, {merge: true});

    const resend = buildResendClient();

    try {
      const result = await resend.emails.send({
        from: EMAIL_FROM.value(),
        to: [email],
        subject: "Your iConstruct OTP Code",
        text: `Your iConstruct verification code is ${otp}. It expires in 10 minutes.`,
        html: otpEmailHtml(otp),
      });

      if (result.error) {
        throw result.error;
      }
    } catch (error) {
      console.error("Failed to send OTP email", error);
      throw mapEmailProviderError(error);
    }

    return {
      success: true,
      message: "OTP sent. Please check your inbox.",
    };
  },
);

exports.verifyEmailOtp = onCall(async (request) => {
  const uid = requireAuth(request);
  const email = readEmail(request);
  const otp = readOtp(request);
  const userRecord = await loadVerifiedUser(uid, email);

  if (userRecord.emailVerified) {
    return {
      success: true,
      message: "Email already verified.",
    };
  }

  const docRef = db.collection("emailOtps").doc(uid);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "No OTP request was found for this account.");
  }

  const data = doc.data();
  const expiresAt = data.expiresAt?.toMillis?.() || 0;
  const attempts = Number(data.attempts || 0);

  if (data.email !== email) {
    throw new HttpsError(
      "permission-denied",
      "OTP does not match the signed-in account email.",
    );
  }

  if (Date.now() > expiresAt) {
    throw new HttpsError("deadline-exceeded", "This OTP has expired. Please resend a new code.");
  }

  if (attempts >= MAX_ATTEMPTS) {
    throw new HttpsError(
      "resource-exhausted",
      "Too many failed attempts. Please resend a new OTP.",
    );
  }

  if (data.codeHash !== hashOtp(uid, otp)) {
    await docRef.set({attempts: attempts + 1}, {merge: true});
    throw new HttpsError("invalid-argument", "Incorrect OTP code.");
  }

  await auth.updateUser(uid, {emailVerified: true});
  await docRef.set({
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    codeHash: admin.firestore.FieldValue.delete(),
    expiresAt: admin.firestore.FieldValue.delete(),
    attempts: admin.firestore.FieldValue.delete(),
  }, {merge: true});

  return {
    success: true,
    message: "Email verified successfully.",
  };
});