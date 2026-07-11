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
    
    if (!record) return new Response("No record found", { status: 400 });

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Fetch tokens based on audience
    let query = supabase.from("users").select("fcm_token").not("fcm_token", "is", null);
    
    if (record.audience !== "all") {
      query = query.eq("user_type", record.audience);
    }

    const { data: users } = await query;
    if (!users || users.length === 0) return new Response("No users found");

    const tokens = users.map((u) => u.fcm_token).filter(Boolean);
    const accessToken = await getAccessToken();
    const projectId = serviceAccountKey.project_id;
    
    // We send individual requests or a loop because the v1 API requires individual messages
    // unless using batching, which fetch() doesn't directly support easily.
    const promises = tokens.map((token) => {
      const fcmMessage = {
        message: {
          token: token,
          notification: {
            title: record.title,
            body: record.message.substring(0, 100),
            ...(record.image_url ? { image: record.image_url } : {})
          },
          data: {
            type: "broadcast",
            broadcast_id: String(record.id),
          },
          android: {
            priority: "high",
            notification: { sound: "default", channel_id: "high_importance_channel" }
          },
          apns: {
            payload: { aps: { sound: "default" } }
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

    return new Response(JSON.stringify({ success: true, count: tokens.length }), { 
      headers: { "Content-Type": "application/json" } 
    });
  } catch (error: any) {
    console.error("Error sending push:", error);
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" } 
    });
  }
});
