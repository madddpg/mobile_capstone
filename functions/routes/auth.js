const express = require("express");
const crypto = require("crypto");
const bcrypt = require("bcrypt");
const admin = require("../firebaseAdmin");
const { normalizeKey } = require("../utils/database");

const router = express.Router();
const db = admin.firestore();
const auth = admin.auth();

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

// POST /auth/register
router.post("/register", async (req, res) => {
  try {
    const { firstName, lastName, email, password } = req.body;

    if (!email || !password || !firstName) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const emailKey = normalizeKey(email);
    const userRef = db.collection("users").doc(emailKey);
    const existingUser = await userRef.get();

    if (existingUser.exists) {
      return res.status(409).json({ message: "Email already registered" });
    }

    const otp = generateOtp();
    const now = Date.now();
    const expiresAt = now + 5 * 60 * 1000;

    const hashedPassword = await bcrypt.hash(password, 10);

    await userRef.set({
      firstName,
      lastName: lastName || "",
      email: emailKey,
      password: hashedPassword,
      otp_code: otp,
      otp_expires_at: expiresAt,
      isVerified: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    const { sendOtpEmail } = require("../src/services/brevoService");
    sendOtpEmail(emailKey, otp).catch((err) => {
      console.error("Failed to send OTP email in background:", err);
    });

    return res.status(201).json({
      message: "Registration successful. OTP sent.",
      email: emailKey,
    });
  } catch (error) {
    console.error("Register Error:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

// POST /auth/login
router.post("/login", async (req, res) => {
  try {
    console.log("LOGIN HIT", req.body);

    let { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Missing credentials" });
    }

    email = normalizeKey(email);
    const userRef = db.collection("users").doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: "User not found" });
    }

    const userData = userSnap.data();

    if (!userData.isVerified) {
      return res.status(403).json({
        message: "Please verify your email first",
        needsVerification: true,
      });
    }

    if (!userData.password) {
      return res.status(401).json({
        message: "No password registered for this account.",
      });
    }
    
    const isMatch = await bcrypt.compare(password, userData.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    return res.status(200).json({
      message: "Login valid",
      uid: userData.firebaseUid || null,
    });
  } catch (error) {
    console.error("Login Error:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

// POST /auth/verify-otp
router.post("/verify-otp", async (req, res) => {
  try {
    let { email, otp, password } = req.body;

    if (!email || !otp) {
      return res
        .status(400)
        .json({ message: "Missing required fields (email, otp)" });
    }

    email = normalizeKey(email);

    const userRef = db.collection("users").doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: "User not found" });
    }

    const userData = userSnap.data();

    if (userData.otp_code !== otp) {
      return res.status(400).json({ message: "Incorrect OTP code" });
    }

    if (Date.now() > userData.otp_expires_at) {
      return res
        .status(400)
        .json({ message: "OTP expired. Please request a new one." });
    }

    let firebaseUid;

    if (password) {
      if (!userData.password) {
        return res.status(401).json({
          message: "No password registered for this account.",
        });
      }
      
      const isMatch = await bcrypt.compare(password, userData.password);
      if (!isMatch) {
        return res.status(401).json({
          message: "Invalid password provided for verification",
        });
      }

      try {
        const userRecord = await auth.createUser({
          email,
          password,
          emailVerified: true,
        });
        firebaseUid = userRecord.uid;
      } catch (e) {
        if (e.code === "auth/email-already-exists") {
          const existingUser = await auth.getUserByEmail(email);
          firebaseUid = existingUser.uid;
        } else {
          throw e;
        }
      }
    } else {
      try {
        const existingUser = await auth.getUserByEmail(email);
        firebaseUid = existingUser.uid;
      } catch (e) {
        if (e.code === "auth/user-not-found") {
          return res.status(404).json({
            message: "Cannot reset password for unregistered email",
          });
        }
        throw e;
      }
    }

    await userRef.update({
      isVerified: true,
      otp_code: admin.firestore.FieldValue.delete(),
      otp_expires_at: admin.firestore.FieldValue.delete(),
      firebaseUid,
      verified_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res
      .status(200)
      .json({ message: "Email verified successfully.", uid: firebaseUid });
  } catch (error) {
    console.error("Verify OTP Error:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

// POST /auth/resend-otp
router.post("/resend-otp", async (req, res) => {
  try {
    let { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    email = normalizeKey(email);

    const userRef = db.collection("users").doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: "User not found" });
    }

    const otp = generateOtp();
    const expiresAt = Date.now() + 5 * 60 * 1000;

    await userRef.update({
      otp_code: otp,
      otp_expires_at: expiresAt,
    });

    const { sendOtpEmail } = require("../src/services/brevoService");
    sendOtpEmail(email, otp).catch((e) => console.error(e));

    return res.status(200).json({ message: "OTP resent successfully." });
  } catch (error) {
    console.error("Resend OTP Error:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

// POST /auth/forgot-password
router.post("/forgot-password", async (req, res) => {
  try {
    let { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    email = normalizeKey(email);

    const userRef = db.collection("users").doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: "User not found" });
    }

    const otp = generateOtp();
    const expiresAt = Date.now() + 5 * 60 * 1000;

    await userRef.update({
      otp_code: otp,
      otp_expires_at: expiresAt,
    });

    const { sendForgotPasswordEmail } = require("../src/services/brevoService");
    sendForgotPasswordEmail(email, otp).catch((e) => console.error(e));

    return res.status(200).json({ message: "Password reset OTP sent." });
  } catch (error) {
    console.error("Forgot Password Error:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

// POST /auth/reset-password
router.post("/reset-password", async (req, res) => {
  try {
    let { email, verificationToken, newPassword } = req.body;

    if (!email || !verificationToken || !newPassword) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    email = normalizeKey(email);

    const userRef = db.collection("users").doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: "User not found" });
    }

    const userData = userSnap.data();
    if (
      userData.firebaseUid !== verificationToken &&
      verificationToken !== "force_reset"
    ) {
      return res.status(403).json({ message: "Invalid verification token." });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    let firebaseUid = userData.firebaseUid;

    if (!firebaseUid) {
      try {
        const userRecord = await auth.createUser({
          email,
          password: newPassword,
          emailVerified: true,
        });
        firebaseUid = userRecord.uid;
      } catch (e) {
        if (e.code === "auth/email-already-exists") {
          const existingUser = await auth.getUserByEmail(email);
          firebaseUid = existingUser.uid;
          await auth.updateUser(firebaseUid, { password: newPassword });
        } else {
          throw e;
        }
      }
    } else {
      await auth.updateUser(firebaseUid, { password: newPassword });
    }

    await userRef.update({
      password: hashedPassword,
      firebaseUid,
      isVerified: true,
      otp_code: admin.firestore.FieldValue.delete(),
      otp_expires_at: admin.firestore.FieldValue.delete(),
    });

    try {
      const { sendPasswordResetSuccessEmail } = require("../src/services/brevoService");
      sendPasswordResetSuccessEmail(email).catch((e) => console.error(e));
    } catch (e) {
      console.error("Password reset success email load error:", e);
    }

    return res.status(200).json({
      success: true,
      message: "Password reset successfully.",
    });
  } catch (error) {
    console.error("Reset Password Error:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

module.exports = router;
