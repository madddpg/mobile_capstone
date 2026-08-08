/**
 * Read the OTP verification proof from a callable request payload.
 *
 * Canonical field: verificationToken
 * Legacy fallback: token (older Flutter clients sent this and broke reset)
 */
function readVerificationTokenFromData(data) {
  const verificationToken = String(
    data?.verificationToken || data?.token || ""
  ).trim();

  if (!verificationToken) {
    const err = new Error(
      "Verify the OTP before finishing registration."
    );
    err.code = "failed-precondition";
    throw err;
  }

  return verificationToken;
}

module.exports = { readVerificationTokenFromData };
