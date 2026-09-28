import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, type Firestore } from 'firebase-admin/firestore';

// A dedicated Admin app avoids accidentally reusing token-only initialization.
export function deletionServices() {
  const name = 'account-deletion';
  let app = getApps().find(app => app.name === name);
  if (!app) {
    const projectId = process.env.KITCHEN_DIARY_FIREBASE_PROJECT_ID || 'kitchen-diary-19971117';
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!raw) throw new Error('Deletion service is not configured');
    const key = JSON.parse(raw) as Record<string, string>;
    if (key.project_id !== projectId || !key.client_email || !key.private_key) throw new Error('Invalid deletion service configuration');
    app = initializeApp({ projectId, credential: cert({ projectId, clientEmail: key.client_email, privateKey: key.private_key.replace(/\\n/g, '\n') }) }, name);
  }
  return { auth: getAuth(app), db: getFirestore(app) };
}

export const ownershipQueries = [
  ['recipes', 'authorId'], ['forum_posts', 'authorId'], ['comments', 'authorId'],
  ['forum_comments', 'authorId'], ['collections', 'authorId'],
  ['activities', 'userId'], ['activities', 'actorId'],
] as const;

/** Authentication is deleted last: failures remain retryable under the same UID. */
export async function deleteOwnedData(uid: string, db: Firestore): Promise<void> {
  // Firestore rules stop other signed-in clients from recreating records during cleanup.
  await db.doc(`accountDeletions/${uid}`).set({ requestedAt: FieldValue.serverTimestamp() }, { merge: true });
  for (const [collection, field] of ownershipQueries) {
    while (true) {
      const page = await db.collection(collection).where(field, '==', uid).limit(100).get();
      if (page.empty) break;
      for (const doc of page.docs) await db.recursiveDelete(doc.ref);
    }
  }
  // Remove this user's social identifiers from other people's documents.
  for (const [collection, field] of [['users','followers'], ['users','following'], ['public_profiles','followers'], ['public_profiles','following'], ['forum_posts','likedBy']] as const) {
    while (true) {
      const page = await db.collection(collection).where(field, 'array-contains', uid).limit(100).get();
      if (page.empty) break;
      const batch = db.batch();
      for (const doc of page.docs) batch.update(doc.ref, { [field]: FieldValue.arrayRemove(uid) });
      await batch.commit();
    }
  }
  await db.recursiveDelete(db.doc(`users/${uid}`)); // Includes every nested nutrition/history/pantry/draft document.
  await db.recursiveDelete(db.doc(`public_profiles/${uid}`));
  // Purchase ownership/audit records are retained for fraud prevention and billing.
  // They confer no access without the deleted Firebase identity.
}
