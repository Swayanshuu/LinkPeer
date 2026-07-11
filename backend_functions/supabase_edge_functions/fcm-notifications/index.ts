import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { google } from "npm:googleapis";

// Get service account credentials from environment variables
const serviceAccountKey = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}");

/**
 * Gets a valid Firebase OAuth2 access token for FCM HTTP v1 API
 */
async function getAccessToken() {
  const jwtClient = new google.auth.JWT(
    serviceAccountKey.client_email,
    null,
    serviceAccountKey.private_key,
    ["https://www.googleapis.com/auth/firebase.messaging"]
  );
  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const { record, type, table } = payload;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    let notificationTitle = "";
    let notificationBody = "";
    let targetUserId = "";
    let notificationType = "";
    let postId = null;
    let commentId = null;

    if (table === "notifications" && type === "INSERT") {
      // The trigger fired because a new notification was inserted
      // So we just need to send the FCM!
      notificationTitle = record.title;
      notificationBody = record.body;
      targetUserId = record.user_id;
      notificationType = record.type;
      postId = record.post_id;
      commentId = record.comment_id;
    } else {
      return new Response(JSON.stringify({ message: "Ignored event" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!targetUserId) {
      return new Response(JSON.stringify({ error: "No target user" }), { status: 400 });
    }

    // Get FCM token for the target user
    const { data: userData, error: userError } = await supabase
      .from("users")
      .select("fcm_token")
      .eq("id", targetUserId)
      .single();

    if (userError || !userData?.fcm_token) {
      console.log(`User ${targetUserId} has no FCM token.`);
      return new Response(JSON.stringify({ message: "No FCM token" }), { status: 200 });
    }

    const fcmToken = userData.fcm_token;
    const accessToken = await getAccessToken();

    // Construct FCM HTTP v1 payload
    const fcmMessage = {
      message: {
        token: fcmToken,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          post_id: postId ? String(postId) : "",
          comment_id: commentId ? String(commentId) : "",
          type: notificationType,
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
            aps: {
              sound: "default"
            }
          }
        }
      },
    };

    const projectId = serviceAccountKey.project_id;
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmMessage),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error("FCM Send Error:", errorText);
      return new Response(JSON.stringify({ error: "FCM delivery failed" }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Internal Error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
