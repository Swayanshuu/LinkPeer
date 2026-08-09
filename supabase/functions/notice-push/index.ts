import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { JWT } from "npm:google-auth-library@9";

// Get service account credentials from environment variables
const serviceAccountKey = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}");

/**
 * Gets a valid Firebase OAuth2 access token for FCM HTTP v1 API
 */
async function getAccessToken() {
  const jwtClient = new JWT({
    email: serviceAccountKey.client_email,
    key: serviceAccountKey.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const { record } = payload;
    
    if (!record) return new Response("No notice record found", { status: 400 });

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Fetch all active users with FCM tokens and IDs
    const { data: users } = await supabase
      .from("users")
      .select("id, fcm_token")
      .not("fcm_token", "is", null);
      
    if (!users || users.length === 0) return new Response("No users found");

    const isImportant = record.is_important === true;
    const notificationTitle = isImportant
      ? `📌 IMPORTANT NOTICE: ${record.title || "New Announcement"}`
      : `📌 New Notice: ${record.title || "College Announcement"}`;

    const notificationBody = record.content
      ? record.content.substring(0, 120)
      : "Tap to view full details on LinkPeer Notice Board.";

    // 1. Insert In-App Notifications into `notifications` table for every user
    try {
      const notificationRows = users.map((u) => ({
        user_id: u.id,
        actor_user_id: record.publisher_id || null,
        type: "NOTICE",
        title: notificationTitle,
        body: notificationBody,
        is_read: false,
      }));

      const chunkSize = 100;
      for (let i = 0; i < notificationRows.length; i += chunkSize) {
        const chunk = notificationRows.slice(i, i + chunkSize);
        await supabase.from("notifications").insert(chunk);
      }
    } catch (dbErr) {
      console.error("Error inserting in-app notifications:", dbErr);
    }

    // 2. Dispatch FCM Push Notifications
    const tokens = users.map((u) => u.fcm_token).filter(Boolean);
    const accessToken = await getAccessToken();
    const projectId = serviceAccountKey.project_id;

    const promises = tokens.map((token) => {
      const fcmMessage = {
        message: {
          token: token,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: "notice",
            notice_id: String(record.id),
          },
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channel_id: "high_importance_channel"
            }
          },
          apns: {
            payload: {
              aps: { sound: "default" }
            }
          }
        }
      };

      return fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmMessage),
      });
    });

    await Promise.all(promises);

    return new Response(
      JSON.stringify({ success: true, notice_id: record.id, recipient_count: tokens.length }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Error sending notice push notification:", error);
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" } 
    });
  }
});
