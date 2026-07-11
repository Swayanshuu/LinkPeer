# Push Notifications Architecture

LinkPeer uses a **secure, serverless event-driven architecture** for sending Firebase Cloud Messaging (FCM) push notifications. 

To keep the application highly secure, we **do not embed Firebase Private Keys or Service Account secrets inside the Flutter application code**. Shipping private keys inside a client application is a major security vulnerability, as malicious users can easily reverse-engineer the APK/IPA and steal the keys to send unauthorized messages or access your databases.

Instead, we use **Supabase Edge Functions** and **PostgreSQL Database Triggers** to handle push notifications entirely server-side.

---

## How It Works (The Notification Flow)

1. **Trigger Event in App**
   When a user performs an action (e.g., commenting on a post), the Flutter app simply inserts a new row into the `notifications` table in Supabase.
   
2. **Database Trigger (PostgreSQL)**
   Supabase detects the new row being inserted into the `notifications` table and instantly fires a PostgreSQL Database Trigger (`on_notification_insert`).

3. **Webhook to Edge Function**
   The Database Trigger uses the `pg_net` extension to send a background HTTP POST request (Webhook) to our secure Supabase Edge Function (`fcm-notifications`), passing along the notification data.

4. **Edge Function Processing**
   The Edge Function receives the webhook and performs the following secure steps:
   - Queries the `users` table to find the target user's `fcm_token`.
   - Reads the `FIREBASE_SERVICE_ACCOUNT` secret (which is securely stored in Supabase's encrypted vault, **not** in the codebase).
   - Generates a short-lived OAuth 2.0 access token using the `google-auth-library`.
   - Constructs the FCM HTTP v1 API payload.
   
5. **FCM Delivery**
   The Edge Function sends the payload to Google's FCM servers, which securely routes the push notification to the correct Android/iOS device.

---

## Setup Instructions

### 1. The Database Tables
Ensure your `users` table has an `fcm_token` column, and that you have a `notifications` table to store the notification history.

### 2. The Edge Function
The code for the Edge Function is located in `supabase/functions/fcm-notifications/index.ts`. 
We use `npm:google-auth-library@9` instead of the heavier `googleapis` package to ensure blazing-fast cold starts and a tiny bundle size.

Deploy the function using the Supabase CLI:
```bash
supabase functions deploy fcm-notifications --no-verify-jwt
```

### 3. The Firebase Secret
Go to your **Firebase Console** ➔ **Project Settings** ➔ **Service Accounts** ➔ **Generate New Private Key**.
Copy the contents of the downloaded JSON file.

Go to your **Supabase Dashboard** ➔ **Edge Functions** ➔ **Secrets**, and create a new secret:
- **Name**: `FIREBASE_SERVICE_ACCOUNT`
- **Value**: (Paste the JSON here)

### 4. The Database Trigger
Run this SQL in your Supabase SQL Editor to wire up the database to the Edge Function:

```sql
CREATE OR REPLACE FUNCTION notify_fcm_edge_function()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/fcm-notifications',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer <YOUR_ANON_KEY>"}'::jsonb,
    body := json_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)
    )::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_notification_insert
AFTER INSERT ON notifications
FOR EACH ROW EXECUTE FUNCTION notify_fcm_edge_function();
```

*(Be sure to replace `<YOUR_PROJECT_REF>` and `<YOUR_ANON_KEY>` with your actual Supabase project details!)*

---

## Advantages of this Architecture
- **100% Secure**: No private keys are ever shipped to the user's phone.
- **Serverless**: Zero maintenance, zero server costs.
- **Instant**: Sub-millisecond latency between database insert and FCM dispatch.
- **Cost-Effective**: Free up to 500,000 invocations per month on Supabase and unlimited free delivery on Firebase.
