# Google Play subscription updates

The purchase endpoint establishes account ownership. The notification endpoint
then refreshes that account's current entitlement directly from Google Play on
renewals, cancellations, expirations, and voided-purchase notifications.

## Cloud configuration

- Project: `kitchen-diary-19971117`
- Endpoint and OIDC audience: `https://kitchendiary.robopioneer.ca/api/google-play/notifications`
- Keyless push identity: `kitchendiary-play-notifications@kitchen-diary-19971117.iam.gserviceaccount.com`
- Topic: `kitchendiary-play-notifications`
- Push subscription: `kitchendiary-play-notifications-push`
- Give `google-play-developer-notifications@system.gserviceaccount.com`
  Publisher on this topic only.
- Give the project's Pub/Sub service agent OpenID-token creation permission on
  the push identity. This identity needs no database or Play permissions.
- In Play monetization setup, enable subscription and voided-purchase
  notifications for this topic, then send a test message.

Resource names above describe the required setup, not proof it is configured.
Verify successful authenticated test delivery after deployment.

## Processing

Google's auth library verifies signature, issuer, expiry and audience. The
endpoint also checks the exact verified push email and KitchenDiary package.
It never logs or stores the purchase token. It locates the current entitlement
using the existing token hash and reuses the Publisher verification path.
Unregistered tokens are ignored: the authenticated app purchase verification
will establish their ownership. A delayed event for a superseded token cannot
replace the newer entitlement. Provider/storage failures return 503 so Pub/Sub
can retry. Successful processing and authenticated test messages return 204.

See [Play RTDN setup](https://developer.android.com/google/play/billing/getting-ready#configure-rtdn)
and [authenticated push](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions).
