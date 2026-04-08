const crypto = require("crypto");
const logger = require("firebase-functions/logger");
const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { Timestamp } = require("firebase-admin/firestore");

const admin = require("./firebaseAdmin");

// Apply production scale defaults
setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
  concurrency: 80,
  timeoutSeconds: 120
});

const { app: apiApp } = require("./api");

// Deploy as an Express-wrapped Cloud Function
exports.api = onRequest({ cors: true }, apiApp);

const db = admin.firestore();
const auth = admin.auth();

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_REQUEST_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;
const VERIFIED_REGISTRATION_WINDOW_MS = 15 * 60 * 1000;
const OTP_COLLECTION = "email_otp";


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
      "Verify the OTP before finishing registration."
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

exports.sendEmailOtp = onCall(async (request) => {
  const email = readEmail(request);
  const now = Date.now();
  const nowTimestamp = Timestamp.now();
  const docRef = db.collection(OTP_COLLECTION).doc(email);

  logger.info("Generating email OTP", { email });

  const existingDoc = await docRef.get();
  const existingData = existingDoc.data();
  const lastRequestTime = existingData?.last_request_time?.toMillis?.() || 0;

  if (lastRequestTime && now - lastRequestTime < OTP_REQUEST_COOLDOWN_MS) {
    logger.warn("OTP requested too soon", { email });
    throw new HttpsError(
      "failed-precondition",
      "Please wait before requesting another code."
    );
  }

  const otp = generateOtp();
  const otpPayload = {
    email,
    otp_code: otp,
    created_at: nowTimestamp,
    expires_at: Timestamp.fromMillis(now + OTP_TTL_MS),
    attempt_count: 0,
    last_request_time: nowTimestamp,
  };

  try {
    await docRef.set(otpPayload);
    logger.info("OTP stored in Firestore", {
      email,
      collection: OTP_COLLECTION,
    });
  } catch (error) {
    logger.error("Failed to store OTP in Firestore", { email, error });
    throw new HttpsError(
      "internal",
      "Could not save the verification code. Please try again."
    );
  }

  const { sendOtpEmail, sendForgotPasswordEmail } = require("./src/services/brevoService");

  try {
    if (request.data?.purpose === "password_reset") {
      await sendForgotPasswordEmail(email, otp);
    } else {
      await sendOtpEmail(email, otp);
    }
    logger.info("OTP email sent via Brevo", { email });
  } catch (error) {
    logger.error("Failed to send OTP email", { email, error });
    await docRef.delete().catch(() => null);
    throw new HttpsError("internal", "Could not send the verification code.");
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
    logger.warn("OTP verification requested without stored code", { email });
    throw new HttpsError(
      "not-found",
      "No verification code was found for this email. Request a new code."
    );
  }

  const data = doc.data();
  const expiresAt = data.expires_at?.toMillis?.() || 0;
  const attemptCount = Number(data.attempt_count || 0);

  if (Date.now() > expiresAt) {
    await docRef.delete();
    logger.warn("Expired OTP attempted", { email });
    throw new HttpsError(
      "deadline-exceeded",
      "This code has expired. Please request a new one."
    );
  }

  if (attemptCount >= MAX_ATTEMPTS) {
    await docRef.delete();
    logger.warn("OTP attempts exceeded", { email, attemptCount });
    throw new HttpsError(
      "resource-exhausted",
      "Too many incorrect attempts. Please request a new code."
    );
  }

  if (data.otp_code !== otp) {
    await docRef.set({ attempt_count: attemptCount + 1 }, { merge: true });
    logger.warn("Incorrect OTP submitted", {
      email,
      attemptCount: attemptCount + 1,
    });
    throw new HttpsError("invalid-argument", "Incorrect OTP code.");
  }

  const verificationToken = crypto.randomBytes(32).toString("hex");
  const verificationTokenHash = hashVerificationToken(verificationToken);
  const verifiedAt = Timestamp.now();

  await docRef.set(
    {
      email,
      created_at: data.created_at || verifiedAt,
      expires_at: data.expires_at,
      last_request_time: data.last_request_time || verifiedAt,
      attempt_count: 0,
      otp_code: admin.firestore.FieldValue.delete(),
      verified_at: verifiedAt,
      verification_expires_at: Timestamp.fromMillis(
        Date.now() + VERIFIED_REGISTRATION_WINDOW_MS
      ),
      verification_token_hash: verificationTokenHash,
    },
    { merge: true }
  );

  logger.info("OTP verified successfully", { email });

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
      "The signed-in account email does not match the verified email."
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
      "Verify the OTP before finishing registration."
    );
  }

  const data = doc.data();
  const verificationExpiresAt = data.verification_expires_at?.toMillis?.() || 0;

  if (!data.verification_token_hash || Date.now() > verificationExpiresAt) {
    await docRef.delete();
    throw new HttpsError(
      "failed-precondition",
      "Your verification session expired. Request a new OTP and verify again."
    );
  }

  if (hashVerificationToken(verificationToken) !== data.verification_token_hash) {
    throw new HttpsError(
      "permission-denied",
      "The verification proof is invalid. Verify the OTP again."
    );
  }

  await auth.updateUser(request.auth.uid, { emailVerified: true });
  await docRef.delete();

  try {
    const { sendWelcomeEmail } = require("./src/services/brevoService");
    await sendWelcomeEmail(email);
  } catch (emailErr) {
    logger.error("Failed to send welcome email", { email, error: emailErr });
  }

  logger.info("Registration email marked verified", {
    email,
    uid: request.auth.uid,
  });

  return {
    success: true,
    message: "Email verified successfully.",
  };
});

exports.resetPasswordWithToken = onCall(async (request) => {
  const email = readEmail(request);
  const verificationToken = readVerificationToken(request);
  const newPassword = String(request.data?.newPassword || "").trim();

  if (newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters."
    );
  }

  const docRef = db.collection(OTP_COLLECTION).doc(email);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError(
      "not-found",
      "No verification found. Please verify your email first."
    );
  }

  const data = doc.data();
  const verificationExpiresAt = data.verification_expires_at?.toMillis?.() || 0;

  if (!data.verification_token_hash || Date.now() > verificationExpiresAt) {
    await docRef.delete();
    throw new HttpsError(
      "failed-precondition",
      "Your verification session has expired. Please verify again."
    );
  }

  if (hashVerificationToken(verificationToken) !== data.verification_token_hash) {
    throw new HttpsError(
      "permission-denied",
      "Invalid verification token. Please verify your email again."
    );
  }

  try {
    const userRecord = await auth.getUserByEmail(email);
    await auth.updateUser(userRecord.uid, { password: newPassword });
    await docRef.delete();

    try {
      const { sendPasswordResetSuccessEmail } = require("./src/services/brevoService");
      await sendPasswordResetSuccessEmail(email);
    } catch (emailErr) {
      logger.error("Failed to send password reset success email", {
        email,
        error: emailErr,
      });
    }

    logger.info("Password reset successfully", { email });
    return { success: true, message: "Password reset successfully." };
  } catch (e) {
    if (e.code === "auth/user-not-found") {
      throw new HttpsError(
        "not-found",
        "No account found with this email address."
      );
    }
    logger.error("Failed to reset password", { email, error: e });
    throw new HttpsError(
      "internal",
      "Failed to reset password. Please try again."
    );
  }
});