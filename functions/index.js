const crypto = require("crypto");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const EMAIL_FROM = defineString("EMAIL_FROM");
const SMTP_HOST = defineString("SMTP_HOST", {default: "smtp.gmail.com"});
const SMTP_PORT = defineString("SMTP_PORT", {default: "465"});
const SMTP_USER = defineString("SMTP_USER");
const SMTP_PASS = defineSecret("SMTP_PASS");

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_REQUEST_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;
const VERIFIED_REGISTRATION_WINDOW_MS = 15 * 60 * 1000;
const OTP_COLLECTION = "email_otp";

function readRequiredStringParam(param, label) {
  const value = String(param.value() || "").trim();

  if (!value) {
    throw new HttpsError(
      "failed-precondition",
      `${label} is not configured for the email OTP function.`,
    );
  }

  return value;
}

function readEmail(request) {
  const email = String(request.data?.email || "").trim().toLowerCase();

  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required.");
  }

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
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

function readVerificationToken(request) {
  const verificationToken = String(request.data?.verificationToken || "").trim();

  if (!verificationToken) {
    throw new HttpsError(
      "failed-precondition",
      "Verify the OTP before finishing registration.",
    );
  }

  return verificationToken;
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function hashVerificationToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function buildTransporter() {
  const port = Number(readRequiredStringParam(SMTP_PORT, "SMTP_PORT"));

  if (!Number.isFinite(port) || port <= 0) {
    throw new HttpsError(
      "failed-precondition",
      "SMTP_PORT must be a valid numeric port for email OTP delivery.",
    );
  }

  return nodemailer.createTransport({
    host: readRequiredStringParam(SMTP_HOST, "SMTP_HOST"),
    port,
    secure: port === 465,
    auth: {
      user: readRequiredStringParam(SMTP_USER, "SMTP_USER"),
      pass: readRequiredStringParam(SMTP_PASS, "SMTP_PASS"),
    },
  });
}

function readEmailFromAddress() {
  return readRequiredStringParam(EMAIL_FROM, "EMAIL_FROM");
}

function mapEmailProviderError(error) {
  const message = String(error?.message || error?.response || "");

  if (
    error?.responseCode === 535 ||
    error?.responseCode === 534 ||
    message.toLowerCase().includes("authentication")
  ) {
    return new HttpsError(
      "failed-precondition",
      "Email delivery is not configured correctly. Check the SMTP host, sender address, username, and password in Firebase Functions config.",
    );
  }

  if (
    error?.responseCode === 421 ||
    message.toLowerCase().includes("rate limit")
  ) {
    return new HttpsError(
      "resource-exhausted",
      "The email provider rate limit has been reached. Please wait and try again later.",
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
        <h2 style="margin: 0 0 14px; font-size: 28px;">Email Verification Code</h2>
        <p style="margin: 0 0 20px; font-size: 14px; line-height: 1.5;">Your verification code is:</p>
        <div style="font-size: 34px; letter-spacing: 10px; font-weight: 700; background: #f1e6d4; border-radius: 16px; padding: 18px; text-align: center;">${otp}</div>
        <p style="margin: 20px 0 0; font-size: 13px; color: #5a6978;">This code will expire in 5 minutes.</p>
        <p style="margin: 8px 0 0; font-size: 13px; color: #5a6978;">Do not share this code with anyone.</p>
      </div>
    </div>
  `;
}

exports.sendEmailOtp = onCall({secrets: [SMTP_PASS]}, async (request) => {
  const email = readEmail(request);
  const now = Date.now();
  const nowTimestamp = admin.firestore.Timestamp.now();
  const docRef = db.collection(OTP_COLLECTION).doc(email);

  logger.info("Generating email OTP", {email});

  const existingDoc = await docRef.get();
  const existingData = existingDoc.data();
  const lastRequestTime = existingData?.last_request_time?.toMillis?.() || 0;

  if (lastRequestTime && now - lastRequestTime < OTP_REQUEST_COOLDOWN_MS) {
    logger.warn("OTP requested too soon", {email});
    throw new HttpsError(
      "failed-precondition",
      "Please wait before requesting another code.",
    );
  }

  const otp = generateOtp();
  const otpPayload = {
    email,
    otp_code: otp,
    created_at: nowTimestamp,
    expires_at: admin.firestore.Timestamp.fromMillis(now + OTP_TTL_MS),
    attempt_count: 0,
    last_request_time: nowTimestamp,
  };

  try {
    await docRef.set(otpPayload);
    logger.info("OTP stored in Firestore", {email, collection: OTP_COLLECTION});
  } catch (error) {
    logger.error("Failed to store OTP in Firestore", {email, error});
    throw new HttpsError(
      "internal",
      "Could not save the verification code. Please try again.",
    );
  }

  let transporter;

  try {
    transporter = buildTransporter();
  } catch (error) {
    logger.error("Email transport configuration is invalid", {email, error});
    await docRef.delete().catch(() => null);
    throw error;
  }

  try {
    await transporter.sendMail({
      from: readEmailFromAddress(),
      to: email,
      subject: "Email Verification Code",
      text: `Your verification code is: ${otp}\nThis code will expire in 5 minutes.\nDo not share this code with anyone.`,
      html: otpEmailHtml(otp),
    });
    logger.info("OTP email sent", {email});
  } catch (error) {
    logger.error("Failed to send OTP email", {email, error});
    await docRef.delete().catch(() => null);
    throw mapEmailProviderError(error);
  }

  return {
    success: true,
    message: "Verification code sent to your email.",
  };
});

exports.verifyEmailOtp = onCall(async (request) => {
  const email = readEmail(request);
  const otp = readOtp(request);
  const docRef = db.collection(OTP_COLLECTION).doc(email);
  const doc = await docRef.get();

  if (!doc.exists) {
    logger.warn("OTP verification requested without stored code", {email});
    throw new HttpsError(
      "not-found",
      "No verification code was found for this email. Request a new code.",
    );
  }

  const data = doc.data();
  const expiresAt = data.expires_at?.toMillis?.() || 0;
  const attemptCount = Number(data.attempt_count || 0);

  if (Date.now() > expiresAt) {
    await docRef.delete();
    logger.warn("Expired OTP attempted", {email});
    throw new HttpsError(
      "deadline-exceeded",
      "This code has expired. Please request a new one.",
    );
  }

  if (attemptCount >= MAX_ATTEMPTS) {
    await docRef.delete();
    logger.warn("OTP attempts exceeded", {email, attemptCount});
    throw new HttpsError(
      "resource-exhausted",
      "Too many incorrect attempts. Please request a new code.",
    );
  }

  if (data.otp_code !== otp) {
    await docRef.set({attempt_count: attemptCount + 1}, {merge: true});
    logger.warn("Incorrect OTP submitted", {
      email,
      attemptCount: attemptCount + 1,
    });
    throw new HttpsError("invalid-argument", "Incorrect OTP code.");
  }

  const verificationToken = crypto.randomBytes(32).toString("hex");
  const verificationTokenHash = hashVerificationToken(verificationToken);
  const verifiedAt = admin.firestore.Timestamp.now();

  await docRef.set(
    {
      email,
      created_at: data.created_at || verifiedAt,
      expires_at: data.expires_at,
      last_request_time: data.last_request_time || verifiedAt,
      attempt_count: 0,
      otp_code: admin.firestore.FieldValue.delete(),
      verified_at: verifiedAt,
      verification_expires_at: admin.firestore.Timestamp.fromMillis(
        Date.now() + VERIFIED_REGISTRATION_WINDOW_MS,
      ),
      verification_token_hash: verificationTokenHash,
    },
    {merge: true},
  );

  logger.info("OTP verified successfully", {email});

  return {
    success: true,
    message: "Email verified. You can finish registration now.",
    verificationToken,
  };
});

exports.finalizeEmailOtpRegistration = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const email = readEmail(request);
  const verificationToken = readVerificationToken(request);
  const userRecord = await auth.getUser(request.auth.uid);
  const signedInEmail = String(userRecord.email || "").trim().toLowerCase();

  if (signedInEmail !== email) {
    throw new HttpsError(
      "permission-denied",
      "The signed-in account email does not match the verified email.",
    );
  }

  if (userRecord.emailVerified) {
    return {
      success: true,
      message: "Email already verified.",
    };
  }

  const docRef = db.collection(OTP_COLLECTION).doc(email);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Verify the OTP before finishing registration.",
    );
  }

  const data = doc.data();
  const verificationExpiresAt = data.verification_expires_at?.toMillis?.() || 0;

  if (!data.verification_token_hash || Date.now() > verificationExpiresAt) {
    await docRef.delete();
    throw new HttpsError(
      "failed-precondition",
      "Your verification session expired. Request a new OTP and verify again.",
    );
  }

  if (hashVerificationToken(verificationToken) !== data.verification_token_hash) {
    throw new HttpsError(
      "permission-denied",
      "The verification proof is invalid. Verify the OTP again.",
    );
  }

  await auth.updateUser(request.auth.uid, {emailVerified: true});
  await docRef.delete();
  logger.info("Registration email marked verified", {
    email,
    uid: request.auth.uid,
  });

  return {
    success: true,
    message: "Email verified successfully.",
  };
});
