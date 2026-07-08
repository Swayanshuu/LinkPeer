import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";
import { encode as base64Encode } from "https://deno.land/std@0.177.0/encoding/base64.ts";

// PhonePe Constants
const PHONEPE_MERCHANT_ID = Deno.env.get("PHONEPE_MERCHANT_ID")!;
const PHONEPE_SALT_KEY = Deno.env.get("PHONEPE_SALT_KEY")!;
const PHONEPE_SALT_INDEX = Deno.env.get("PHONEPE_SALT_INDEX") || "1";
const PHONEPE_ENV = Deno.env.get("PHONEPE_ENV") || "UAT"; // 'UAT' or 'PROD'

const PHONEPE_BASE_URL = PHONEPE_ENV === "PROD" 
  ? "https://api.phonepe.com/apis/hermes/pg/v1/pay" 
  : "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/pay";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function generateSHA256(data: string) {
  const messageBuffer = new TextEncoder().encode(data);
  const hashBuffer = await crypto.subtle.digest("SHA-256", messageBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const action = url.searchParams.get("action");

    if (action === "createOrder") {
      const { user_id, plan_type, amount, phone_number } = await req.json();

      if (!user_id || !plan_type || !amount) {
        return new Response(JSON.stringify({ error: "Missing required fields" }), {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }

      // Generate a unique transaction ID
      const transactionId = `TXN_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

      // Save initial pending payment to database
      const { error: dbError } = await supabase.from('payments').insert({
        user_id,
        plan_type,
        amount,
        transaction_id: transactionId,
        payment_provider: 'phonepe',
        status: 'pending'
      });

      if (dbError) throw dbError;

      // Prepare PhonePe payload
      const payload = {
        merchantId: PHONEPE_MERCHANT_ID,
        merchantTransactionId: transactionId,
        merchantUserId: user_id,
        amount: amount * 100, // Amount in paise
        redirectUrl: `${url.origin}${url.pathname}?action=callback&transactionId=${transactionId}`,
        redirectMode: "POST",
        callbackUrl: `${url.origin}${url.pathname}?action=callback&transactionId=${transactionId}`,
        mobileNumber: phone_number || "9999999999",
        paymentInstrument: {
          type: "PAY_PAGE",
        },
      };

      const base64Payload = btoa(JSON.stringify(payload));
      
      // Calculate X-VERIFY checksum: SHA256(base64Payload + "/pg/v1/pay" + saltKey) + ### + saltIndex
      const stringToHash = base64Payload + "/pg/v1/pay" + PHONEPE_SALT_KEY;
      const sha256 = await generateSHA256(stringToHash);
      const checksum = `${sha256}###${PHONEPE_SALT_INDEX}`;

      // Call PhonePe API
      const phonepeResponse = await fetch(PHONEPE_BASE_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-VERIFY": checksum,
          "accept": "application/json"
        },
        body: JSON.stringify({ request: base64Payload }),
      });

      const phonepeData = await phonepeResponse.json();

      if (phonepeData.success) {
        return new Response(JSON.stringify({ 
          success: true, 
          paymentUrl: phonepeData.data.instrumentResponse.redirectInfo.url,
          transactionId
        }), {
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      } else {
        throw new Error(phonepeData.message || "Failed to initiate payment");
      }
    }

    if (action === "callback") {
      // Handle the callback from PhonePe
      const bodyText = await req.text();
      let responseData;
      
      try {
        responseData = JSON.parse(bodyText);
      } catch (e) {
        // If it's x-www-form-urlencoded from a POST redirect
        const params = new URLSearchParams(bodyText);
        const base64Response = params.get('response');
        if (base64Response) {
          responseData = JSON.parse(atob(base64Response));
        }
      }

      if (!responseData || !responseData.data) {
        return new Response("Invalid callback", { status: 400 });
      }

      const { merchantTransactionId, code } = responseData.data;

      if (code === 'PAYMENT_SUCCESS') {
        // 1. Update Payment Status
        await supabase.from('payments')
          .update({ status: 'success' })
          .eq('transaction_id', merchantTransactionId);

        // 2. Fetch the payment details to know user and plan
        const { data: paymentInfo } = await supabase.from('payments')
          .select('*')
          .eq('transaction_id', merchantTransactionId)
          .single();

        if (paymentInfo) {
          // 3. Create or update Subscription
          const startDate = new Date();
          const endDate = new Date();
          endDate.setMonth(endDate.getMonth() + 1); // 1 month subscription

          await supabase.from('subscriptions').insert({
            user_id: paymentInfo.user_id,
            plan_type: paymentInfo.plan_type,
            amount: paymentInfo.amount,
            status: 'active',
            transaction_id: merchantTransactionId,
            start_date: startDate.toISOString(),
            end_date: endDate.toISOString()
          });

          // 4. Update Users table
          await supabase.from('users')
            .update({
              subscription_plan: paymentInfo.plan_type,
              subscription_status: 'active',
              subscription_expiry: endDate.toISOString(),
              verified_badge: true,
              ranking_score: paymentInfo.plan_type === 'premium_pro' ? 100 : 50
            })
            .eq('id', paymentInfo.user_id);
        }

        // Redirect back to app via deep link
        return Response.redirect(`linkpeer://payment/success?txnId=${merchantTransactionId}`, 302);
      } else {
        // Payment failed
        await supabase.from('payments')
          .update({ status: 'failed' })
          .eq('transaction_id', merchantTransactionId);
          
        return Response.redirect(`linkpeer://payment/failed?txnId=${merchantTransactionId}`, 302);
      }
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      status: 400,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });

  } catch (error) {
    console.error("Payment error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});
