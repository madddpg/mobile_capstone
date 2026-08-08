/**
 * Unit tests for the callable verification-token reader.
 * Run: node --test functions/read_verification_token.test.js
 */
import test from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { readVerificationTokenFromData } = require("./src/readVerificationToken.js");

test("reads canonical verificationToken field", () => {
  assert.equal(
    readVerificationTokenFromData({ verificationToken: "abc123" }),
    "abc123"
  );
});

test("falls back to legacy token field", () => {
  assert.equal(readVerificationTokenFromData({ token: "legacy" }), "legacy");
});

test("prefers verificationToken over token", () => {
  assert.equal(
    readVerificationTokenFromData({
      verificationToken: "canonical",
      token: "legacy",
    }),
    "canonical"
  );
});

test("throws when neither field is present", () => {
  assert.throws(
    () => readVerificationTokenFromData({}),
    (err) => err?.code === "failed-precondition"
  );
});
