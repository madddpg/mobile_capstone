/**
 * Firestore security rules regression tests for iConstruct.
 *
 * Requires the Firestore emulator:
 *   firebase emulators:exec --only firestore "node --test test/rules/firestore.rules.test.mjs"
 *
 * Or with deps installed at repo root:
 *   npm run test:rules
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(join(__dirname, '../../firestore.rules'), 'utf8');

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'iconstruct-rules-test',
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });
});

test.after(async () => {
  await env?.cleanup();
});

test.beforeEach(async () => {
  await env.clearFirestore();
});

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

test('shop cannot forge a rival shop quotation', async () => {
  const admin = env.authenticatedContext('builder-1').firestore();
  // Seed post + approved shop via rules-bypassing admin context.
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('projectPosts/post-1').set({
      userId: 'builder-1',
      projectName: 'Bath',
      materials: [],
      status: 'open',
      quotationCount: 0,
    });
    await db.doc('shops/shop-a').set({ status: 'approved', name: 'A' });
    await db.doc('shops/shop-b').set({ status: 'approved', name: 'B' });
  });

  const shopB = authed('shop-b');
  await assertFails(
    shopB.doc('projectPosts/post-1/quotations/shop-a').set({
      shopId: 'shop-a',
      postId: 'post-1',
      estimatedTotal: 1,
      status: 'submitted',
    }),
  );
});

test('approved shop can submit its own quotation', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('projectPosts/post-1').set({
      userId: 'builder-1',
      projectName: 'Bath',
      materials: [],
      status: 'open',
      quotationCount: 0,
    });
    await db.doc('shops/shop-a').set({ status: 'approved', name: 'A' });
  });

  const shopA = authed('shop-a');
  await assertSucceeds(
    shopA.doc('projectPosts/post-1/quotations/shop-a').set({
      shopId: 'shop-a',
      postId: 'post-1',
      estimatedTotal: 1200,
      status: 'submitted',
    }),
  );
});

test('shop cannot self-approve', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('shops/shop-a').set({
      status: 'pending',
      name: 'A',
    });
  });

  const shopA = authed('shop-a');
  await assertFails(
    shopA.doc('shops/shop-a').update({ status: 'approved' }),
  );
});

test('clients cannot create notifications for other users', async () => {
  const attacker = authed('attacker');
  await assertFails(
    attacker.doc('notifications/n1').set({
      recipientId: 'victim',
      type: 'new_quotation',
      isRead: false,
      title: 'Fake',
    }),
  );
});

test('builder can mark own notification read only', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('notifications/n1').set({
      recipientId: 'builder-1',
      type: 'new_quotation',
      isRead: false,
      title: 'New bid',
      postId: 'post-1',
    });
  });

  const builder = authed('builder-1');
  await assertSucceeds(
    builder.doc('notifications/n1').update({ isRead: true }),
  );
  await assertFails(
    builder.doc('notifications/n1').update({
      isRead: true,
      title: 'hijacked',
    }),
  );
});

test('unrelated builder cannot read another builder post', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('projectPosts/post-1').set({
      userId: 'builder-1',
      projectName: 'Bath',
      materials: ['tiles'],
      status: 'open',
      quotationCount: 0,
    });
  });

  const stranger = authed('builder-2');
  await assertFails(stranger.doc('projectPosts/post-1').get());
});

test('owner cannot forge isVerified on their profile', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('users/builder-1').set({
      email: 'builder@example.com',
      isVerified: false,
      firstName: 'Pat',
      lastName: 'Builder',
    });
  });

  const builder = authed('builder-1');
  await assertFails(
    builder.doc('users/builder-1').update({ isVerified: true }),
  );
  await assertSucceeds(
    builder.doc('users/builder-1').update({ firstName: 'Patched' }),
  );
});

test('owner cannot create a pre-verified profile', async () => {
  const builder = authed('builder-1');
  await assertFails(
    builder.doc('users/builder-1').set({
      email: 'builder@example.com',
      isVerified: true,
      firstName: 'Pat',
      lastName: 'Builder',
    }),
  );
  await assertSucceeds(
    builder.doc('users/builder-1').set({
      email: 'builder@example.com',
      isVerified: false,
      firstName: 'Pat',
      lastName: 'Builder',
    }),
  );
});

test('shop cannot rewrite quotation after it was accepted', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('projectPosts/post-1').set({
      userId: 'builder-1',
      projectName: 'Bath',
      materials: [],
      status: 'offer_accepted',
      quotationCount: 1,
      selectedQuotationId: 'shop-a',
    });
    await db.doc('shops/shop-a').set({ status: 'approved', name: 'A' });
    await db.doc('projectPosts/post-1/quotations/shop-a').set({
      shopId: 'shop-a',
      postId: 'post-1',
      estimatedTotal: 1200,
      status: 'accepted',
    });
  });

  const shopA = authed('shop-a');
  await assertFails(
    shopA.doc('projectPosts/post-1/quotations/shop-a').update({
      estimatedTotal: 1,
      status: 'submitted',
    }),
  );
});
