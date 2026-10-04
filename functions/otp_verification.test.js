const assert = require("assert");
const {
  OTP_CLEAR,
  nextOtpAttemptState,
  resolveClientIp,
} = require("./src/otpVerification");

function baseDoc(overrides = {}) {
  return {
    otp_code: "123456",
    expires_at: { toMillis: () => Date.now() + 60_000 },
    attempt_count: 0,
    send_count_day: 7,
    last_request_time: { toMillis: () => Date.now() },
    ...overrides,
  };
}

function run(data, otp, attemptCount) {
  return nextOtpAttemptState({
    data: data && { ...data, attempt_count: attemptCount ?? data.attempt_count },
    otp,
    nowMs: Date.now(),
    maxAttempts: 5,
    verificationWindowMs: 15 * 60 * 1000,
    createToken: () => "token-abc",
    hashToken: (t) => `hash:${t}`,
  });
}

// Concurrent wrong guesses must each bump from the count they observe.
const first = run(baseDoc(), "000000", 0);
assert.strictEqual(first.outcome, "wrong");
assert.strictEqual(first.patch.attempt_count, 1);

const second = run(baseDoc(), "000001", first.patch.attempt_count);
assert.strictEqual(second.outcome, "wrong");
assert.strictEqual(second.patch.attempt_count, 2);

const fifth = run(baseDoc(), "000005", 4);
assert.strictEqual(fifth.outcome, "wrong");
assert.strictEqual(fifth.patch.attempt_count, 5);

const sixth = run(baseDoc(), "000006", 5);
assert.strictEqual(sixth.outcome, "exhausted");
assert.strictEqual(sixth.patch.otp_code, OTP_CLEAR);
assert.ok(!("send_count_day" in sixth.patch), "lockout must not wipe send caps");

const expired = run(
  baseDoc({
    expires_at: { toMillis: () => Date.now() - 1 },
    send_count_day: 9,
  }),
  "123456",
  0
);
assert.strictEqual(expired.outcome, "expired");
assert.strictEqual(expired.patch.otp_code, OTP_CLEAR);
assert.ok(!("send_count_day" in expired.patch), "expiry must not wipe send caps");

const ok = run(baseDoc(), "123456", 2);
assert.strictEqual(ok.outcome, "ok");
assert.strictEqual(ok.verificationToken, "token-abc");
assert.strictEqual(ok.patch.verification_token_hash, "hash:token-abc");
assert.strictEqual(ok.patch.otp_code, OTP_CLEAR);

const missing = run(null, "123456");
assert.strictEqual(missing.outcome, "missing");

// IP: prefer platform IP; never trust the first XFF hop alone.
assert.strictEqual(
  resolveClientIp({
    ip: "203.0.113.9",
    headers: { "x-forwarded-for": "1.2.3.4, 203.0.113.9" },
  }),
  "203.0.113.9"
);
assert.strictEqual(
  resolveClientIp({
    headers: { "x-forwarded-for": "1.2.3.4, 198.51.100.7" },
  }),
  "198.51.100.7",
  "fallback must use last hop, not client-supplied first hop"
);
assert.strictEqual(
  resolveClientIp({
    headers: { "x-forwarded-for": "1.2.3.4" },
  }),
  "1.2.3.4"
);

console.log("otpVerification tests passed");
