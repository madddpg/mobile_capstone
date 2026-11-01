/**
 * Registration OTP must not be issued for an email that already has a Firebase
 * Auth user. Password-reset and login-reverify OTPs are allowed (inbox proof
 * for an account that already exists).
 *
 * @param {string} purpose raw purpose from the callable payload
 * @param {boolean} authUserExists whether auth.getUserByEmail found a user
 * @returns {null | { code: string, message: string }}
 */
function registrationOtpBlockReason(purpose, authUserExists) {
  const normalized = String(purpose || "").trim();
  if (normalized === "password_reset" || normalized === "login_reverify") {
    return null;
  }
  if (!authUserExists) return null;
  return {
    code: "already-exists",
    message: "This email already has an account. Please sign in.",
  };
}

/**
 * Unauthenticated OTP verify must only mint a verification token. It must never
 * promote whatever Auth uid currently owns the email — that lets a pre-created
 * attacker account inherit the victim's OTP proof.
 */
function otpVerifyPromotesAuthByEmail() {
  return false;
}

module.exports = {
  registrationOtpBlockReason,
  otpVerifyPromotesAuthByEmail,
};
