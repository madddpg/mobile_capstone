/**
 * After a credential change, force every device to re-authenticate.
 *
 * Firebase Auth does not revoke refresh tokens when Admin `updateUser`
 * (or the client `updatePassword`) changes a password. Without an explicit
 * revoke, a stolen/shared session keeps working after the victim resets or
 * changes their password.
 *
 * Clearing `users/{uid}.fcmTokens` stops push delivery to those devices until
 * the rightful owner signs in again and re-binds a token.
 *
 * @param {{ auth: import('firebase-admin').auth.Auth, db: FirebaseFirestore.Firestore, uid: string, FieldValue: typeof import('firebase-admin').firestore.FieldValue, Timestamp?: FirebaseFirestore.Timestamp }} deps
 */
async function revokeUserSessions({ auth, db, uid, FieldValue, Timestamp }) {
  if (!uid || typeof uid !== "string") {
    throw new Error("uid is required to revoke sessions");
  }

  await auth.revokeRefreshTokens(uid);

  const payload = {
    fcmTokens: [],
  };
  if (Timestamp && typeof Timestamp.now === "function") {
    payload.sessionsRevokedAt = Timestamp.now();
  } else if (FieldValue && typeof FieldValue.serverTimestamp === "function") {
    payload.sessionsRevokedAt = FieldValue.serverTimestamp();
  }

  await db.collection("users").doc(uid).set(payload, { merge: true });

  return { uid, revoked: true };
}

module.exports = { revokeUserSessions };
