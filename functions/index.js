const crypto = require("crypto");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const SMTP_HOST = defineString("SMTP_HOST", {default: "smtp.gmail.com"});
const SMTP_PORT = defineString("SMTP_PORT", {default: "465"});
const SMTP_FROM_EMAIL = defineString("SMTP_FROM_EMAIL");
const SMTP_FROM_NAME = defineString("SMTP_FROM_NAME", {default: "iConstruct"});
const SMTP_USER = defineSecret("SMTP_USER");
const SMTP_PASS = defineSecret("SMTP_PASS");

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

function buildTransport() {
  return nodemailer.createTransport({
    host: SMTP_HOST.value(),
    port: Number(SMTP_PORT.value()),
    secure: Number(SMTP_PORT.value()) === 465,
    auth: {
      user: SMTP_USER.value(),
      pass: SMTP_PASS.value(),
    },
  });
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
  {secrets: [SMTP_USER, SMTP_PASS]},
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

    const transporter = buildTransport();
    await transporter.sendMail({
      from: `"${SMTP_FROM_NAME.value()}" <${SMTP_FROM_EMAIL.value()}>`,
      to: email,
      subject: "Your iConstruct OTP Code",
      text: `Your iConstruct verification code is ${otp}. It expires in 10 minutes.`,
      html: otpEmailHtml(otp),
    });

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