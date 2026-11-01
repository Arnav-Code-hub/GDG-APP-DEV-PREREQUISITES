// Firestore rule tests. Run from this folder with `npm test`, which starts
// the local emulator for the demo-quizorbit project (never a real project).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const ID = 'AbCdEfGhIjKlMnOpQr12';
let env;

const attempt = (overrides = {}) => ({
  categoryId: 'anime',
  topicId: 'shonen',
  mode: 'practice',
  timed: false,
  score: 7,
  total: 10,
  questionSetVersion: '2026-11-01.1',
  completedAt: Timestamp.now(),
  questionIds: Array.from({ length: 10 }, (_, i) => `anime-q${i}`),
  selectedIndices: [0, 1, 2, 3, 0, 1, 2, 3, 0, 1],
  ...overrides,
});

const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const ref = (firestore, uid = 'alice', id = ID) => doc(firestore, `users/${uid}/attempts/${id}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-quizorbit',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(() => env.cleanup());

test('an owner can save and read a completed attempt', async () => {
  await assertSucceeds(setDoc(ref(db('alice')), attempt()));
  await assertSucceeds(getDoc(ref(db('alice'))));
});

test('signed-out players cannot read or write', async () => {
  await assertFails(setDoc(ref(db(null)), attempt()));
  await assertFails(getDoc(ref(db(null))));
});

test('one account cannot read or write another account', async () => {
  await assertSucceeds(setDoc(ref(db('alice')), attempt()));
  await assertFails(getDoc(ref(db('bob'), 'alice')));
  await assertFails(setDoc(ref(db('bob'), 'alice', 'ZZZZZZZZZZZZZZZZZZZZ'), attempt()));
});

test('an identical retry is accepted; a changed record is not', async () => {
  const data = attempt();
  await assertSucceeds(setDoc(ref(db('alice')), data));
  await assertSucceeds(setDoc(ref(db('alice')), data));
  await assertFails(setDoc(ref(db('alice')), { ...data, score: 10 }));
  await assertFails(updateDoc(ref(db('alice')), { score: 10 }));
});

test('attempts cannot be deleted', async () => {
  await assertSucceeds(setDoc(ref(db('alice')), attempt()));
  await assertFails(deleteDoc(ref(db('alice'))));
});

for (const [name, data] of [
  ['unknown category', attempt({ categoryId: 'music' })],
  ['score above total', attempt({ score: 11 })],
  ['negative score', attempt({ score: -1 })],
  ['fractional score', attempt({ score: 6.5 })],
  ['wrong total', attempt({ total: 20 })],
  ['extra field', attempt({ comment: 'hi' })],
  ['short answer list', attempt({ selectedIndices: [0, 1] })],
  ['answers not a list', attempt({ questionIds: 'anime-q0' })],
  ['unknown mode', attempt({ mode: 'ranked' })],
  ['non-boolean timed', attempt({ timed: 'yes' })],
  ['daily mode on a practice ID', attempt({ mode: 'daily' })],
  ['missing field', (({ questionSetVersion, ...rest }) => rest)(attempt())],
  ['string timestamp', attempt({ completedAt: '2026-11-01' })],
  ['future timestamp', attempt({ completedAt: Timestamp.fromMillis(Date.now() + 3600e3) })],
]) {
  test(`rejects ${name}`, async () => {
    await assertFails(setDoc(ref(db('alice')), data));
  });
}

test('rejects a malformed attempt ID', async () => {
  await assertFails(setDoc(ref(db('alice'), 'alice', 'short'), attempt()));
});

test('nothing outside the attempts path is writable', async () => {
  await assertFails(setDoc(doc(db('alice'), 'users/alice'), { name: 'x' }));
  await assertFails(setDoc(doc(db('alice'), 'leaderboard/top'), { score: 10 }));
});

test('a daily attempt uses its fixed ID and cannot be stored twice', async () => {
  const id = 'daily-anime-20261101';
  const daily = attempt({ mode: 'daily', topicId: null });
  await assertSucceeds(setDoc(ref(db('alice'), 'alice', id), daily));
  await assertSucceeds(setDoc(ref(db('alice'), 'alice', id), daily));
  await assertFails(setDoc(ref(db('alice'), 'alice', id), { ...daily, score: 10 }));
  await assertFails(
    setDoc(ref(db('alice'), 'alice', 'daily-sports-20261101'), daily),
  );
  await assertFails(setDoc(ref(db('alice'), 'alice', 'daily-anime-2026'), daily));
});

const report = (overrides = {}) => ({
  uid: 'alice',
  questionId: 'anime-naruto-tailed-beast',
  bankVersion: '2026-11-01.2',
  reason: 'wrong-answer',
  note: '',
  createdAt: serverTimestamp(),
  ...overrides,
});

test('one report per player per question, never readable', async () => {
  const q = 'anime-naruto-tailed-beast';
  const at = (uid, id = `alice_${q}`) => doc(db(uid), `questionReports/${id}`);
  await assertSucceeds(setDoc(at('alice'), report()));
  await assertFails(setDoc(at('alice'), report({ reason: 'typo' })));
  await assertFails(setDoc(at('alice', 'alice_other-id'), report()));
  await assertFails(setDoc(at('alice', `alice_${q}2`), report()));
  await assertFails(setDoc(at(null), report()));
  await assertFails(setDoc(at('alice', `bob_${q}`), report({ uid: 'bob' })));
  const fresh = (overrides) => setDoc(at('alice', 'alice_sports-tennis-love'),
    report({ questionId: 'sports-tennis-love', ...overrides }));
  await assertFails(fresh({ reason: 'spam' }));
  await assertFails(fresh({ note: 'x'.repeat(301) }));
  await assertFails(fresh({ createdAt: Timestamp.now() }));
  await assertFails(getDoc(at('alice')));
});

test('the published bank is public to read and closed to writes', async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'questionBanks/current'), { version: 'v', json: '{}' }),
  );
  await assertSucceeds(getDoc(doc(db(null), 'questionBanks/current')));
  await assertFails(
    setDoc(doc(db('alice'), 'questionBanks/current'), { version: 'x', json: '{}' }),
  );
});
