const assert = require("assert");
const {
  registrationOtpBlockReason,
  otpVerifyPromotesAuthByEmail,
} = require("./src/otpAccountGuard");

function testRegistrationBlockedWhenAuthExists() {
  const blocked = registrationOtpBlockReason("", true);
  assert.ok(blocked);
  assert.strictEqual(blocked.code, "already-exists");
}

function testRegistrationAllowedWhenNoAuth() {
  assert.strictEqual(registrationOtpBlockReason("register", false), null);
  assert.strictEqual(registrationOtpBlockReason("", false), null);
}

function testPasswordResetAllowedEvenWhenAuthExists() {
  assert.strictEqual(registrationOtpBlockReason("password_reset", true), null);
}

function testLoginReverifyAllowedWhenAuthExists() {
  assert.strictEqual(registrationOtpBlockReason("login_reverify", true), null);
}

function testVerifyNeverPromotesByEmail() {
  assert.strictEqual(otpVerifyPromotesAuthByEmail(), false);
}

testRegistrationBlockedWhenAuthExists();
testRegistrationAllowedWhenNoAuth();
testPasswordResetAllowedEvenWhenAuthExists();
testLoginReverifyAllowedWhenAuthExists();
testVerifyNeverPromotesByEmail();
console.log("otp_account_guard.test.js: ok");
