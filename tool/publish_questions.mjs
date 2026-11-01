// Publishes assets/questions/questions.json to Firestore at
// questionBanks/current, so players get new questions without an app update.
//
// Needs admin credentials, which bypass the security rules. Never ship them
// in the app. Either:
//   gcloud auth application-default login
// or point GOOGLE_APPLICATION_CREDENTIALS at a service-account key file kept
// outside this repository.
//
// Usage (from this folder):
//   npm install
//   npm run publish -- --project quizorbit-gdg-26
//
// The app re-validates whatever it downloads and falls back to its bundled
// bank if the published one is invalid or older, so a bad publish cannot
// break play.
import { readFileSync } from 'node:fs';

import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const projectFlag = process.argv.indexOf('--project');
const projectId = projectFlag > 0 ? process.argv[projectFlag + 1] : undefined;
if (!projectId) {
  console.error('Pass --project <firebase-project-id>.');
  process.exit(1);
}

const source = readFileSync(
  new URL('../assets/questions/questions.json', import.meta.url),
  'utf8',
);
const bank = JSON.parse(source);

// A quick sanity check; the app performs the full validation.
const perTopic = new Map(bank.topics.map((t) => [t.id, 0]));
for (const q of bank.questions) {
  if (!perTopic.has(q.topic)) throw new Error(`Unknown topic in ${q.id}`);
  if (q.options?.length !== 4) throw new Error(`${q.id} needs 4 options`);
  perTopic.set(q.topic, perTopic.get(q.topic) + 1);
}
for (const [topic, count] of perTopic) {
  if (count < 10) throw new Error(`Topic ${topic} has only ${count} questions`);
}

initializeApp({ credential: applicationDefault(), projectId });
await getFirestore().doc('questionBanks/current').set({
  version: bank.version,
  json: source,
  publishedAt: FieldValue.serverTimestamp(),
});
console.log(
  `Published ${bank.questions.length} questions (version ${bank.version}) to ${projectId}.`,
);
