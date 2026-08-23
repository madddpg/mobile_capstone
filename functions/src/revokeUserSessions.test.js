/**
 * Unit tests for revokeUserSessions (no Firebase emulator required).
 *
 * Run: node --test functions/src/revokeUserSessions.test.js
 */
const { describe, it, mock } = require("node:test");
const assert = require("node:assert/strict");
const { revokeUserSessions } = require("./revokeUserSessions");

describe("revokeUserSessions", () => {
  it("revokes refresh tokens and clears fcmTokens for the uid", async () => {
    const calls = { revoke: [], set: [] };
    const auth = {
      revokeRefreshTokens: mock.fn(async (uid) => {
        calls.revoke.push(uid);
      }),
    };
    const docRef = {
      set: mock.fn(async (payload, opts) => {
        calls.set.push({ payload, opts });
      }),
    };
    const db = {
      collection: mock.fn(() => ({
        doc: mock.fn(() => docRef),
      })),
    };
    const Timestamp = { now: mock.fn(() => "TS_NOW") };
    const FieldValue = { serverTimestamp: mock.fn(() => "SERVER_TS") };

    const result = await revokeUserSessions({
      auth,
      db,
      uid: "user-1",
      FieldValue,
      Timestamp,
    });

    assert.deepEqual(result, { uid: "user-1", revoked: true });
    assert.deepEqual(calls.revoke, ["user-1"]);
    assert.equal(calls.set.length, 1);
    assert.deepEqual(calls.set[0].payload, {
      fcmTokens: [],
      sessionsRevokedAt: "TS_NOW",
    });
    assert.deepEqual(calls.set[0].opts, { merge: true });
  });

  it("rejects a missing uid before touching Auth", async () => {
    const auth = {
      revokeRefreshTokens: mock.fn(async () => {
        throw new Error("should not run");
      }),
    };
    await assert.rejects(
      () =>
        revokeUserSessions({
          auth,
          db: {},
          uid: "",
          FieldValue: {},
        }),
      /uid is required/,
    );
    assert.equal(auth.revokeRefreshTokens.mock.callCount(), 0);
  });
});
