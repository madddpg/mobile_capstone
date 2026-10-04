/**
 * Pure OTP verification state machine for email_otp docs.
 * Used by confirmBuilderEmailOtp so attempt limits stay atomic under concurrency.
 */

const OTP_CLEAR = Symbol("otp_clear");

function nextOtpAttemptState({
  data,
  otp,
  nowMs,
  maxAttempts,
  verificationWindowMs,
  createToken,
  hashToken,
}) {
  if (!data) {
    return {
      outcome: "missing",
      error: {
        code: "not-found",
        message: "No verification code was found for this email. Request a new code.",
      },
    };
  }

  const expiresAt = data.expires_at?.toMillis?.() || Number(data.expires_at) || 0;
  const attemptCount = Number(data.attempt_count || 0);
  const storedOtp = String(data.otp_code ?? "").replace(/\D/g, "").trim();

  // Never delete the whole doc on expiry/lockout — send counters live here.
  if (!storedOtp || (expiresAt && nowMs > expiresAt)) {
    return {
      outcome: "expired",
      patch: {
        otp_code: OTP_CLEAR,
        attempt_count: Math.max(attemptCount, maxAttempts),
      },
      error: {
        code: "deadline-exceeded",
        message: "This code has expired. Please request a new one.",
      },
    };
  }

  if (attemptCount >= maxAttempts) {
    return {
      outcome: "exhausted",
      patch: {
        otp_code: OTP_CLEAR,
      },
      error: {
        code: "resource-exhausted",
        message: "Too many incorrect attempts. Please request a new code.",
      },
    };
  }

  if (storedOtp !== otp) {
    return {
      outcome: "wrong",
      patch: {
        attempt_count: attemptCount + 1,
      },
      error: {
        code: "invalid-argument",
        message: "Incorrect OTP code.",
      },
      attemptCount: attemptCount + 1,
    };
  }

  const verificationToken = createToken();
  return {
    outcome: "ok",
    verificationToken,
    patch: {
      attempt_count: 0,
      otp_code: OTP_CLEAR,
      verified_at: nowMs,
      verification_expires_at: nowMs + verificationWindowMs,
      verification_token_hash: hashToken(verificationToken),
    },
  };
}

/**
 * Prefer platform-resolved IP; only fall back to the last X-Forwarded-For hop.
 * The first XFF entry is client-controlled and must not gate rate limits.
 */
function resolveClientIp(rawRequest) {
  const direct =
    (typeof rawRequest?.ip === "string" && rawRequest.ip.trim()) ||
    rawRequest?.socket?.remoteAddress ||
    "";
  if (direct && direct !== "unknown") return direct;

  const forwarded = rawRequest?.headers?.["x-forwarded-for"];
  if (typeof forwarded !== "string" || !forwarded.trim()) return "";

  const parts = forwarded
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean);
  return parts.length ? parts[parts.length - 1] : "";
}

module.exports = {
  OTP_CLEAR,
  nextOtpAttemptState,
  resolveClientIp,
};
