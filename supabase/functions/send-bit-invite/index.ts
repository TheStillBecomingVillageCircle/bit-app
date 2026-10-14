// Supabase Edge Function: send-bit-invite
// Required function secrets: RESEND_API_KEY and BIT_FROM_EMAIL
// Deploy with Supabase CLI or the Supabase dashboard's Edge Function editor.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://thestillbecomingvillagecircle.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return reply({ error: "Please sign in to BIT first." }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const resendKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("BIT_FROM_EMAIL");
    if (!supabaseUrl || !anonKey || !resendKey || !fromEmail) {
      return reply({ error: "BIT email delivery is not configured yet. The email service needs to be connected by the app administrator." }, 503);
    }

    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) return reply({ error: "Your BIT session expired. Sign in again." }, 401);

    const body = await req.json();
    const email = String(body.email || "").trim().toLowerCase();
    const name = String(body.name || "my person").trim().slice(0, 100);
    const note = String(body.note || "I would love for us to try a new way to communicate with care and intention.").trim().slice(0, 2000);
    const inviteUrl = String(body.inviteUrl || "");
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return reply({ error: "Enter a valid email address." }, 400);
    if (!inviteUrl.startsWith("https://thestillbecomingvillagecircle.github.io/bit-app/?invite=")) {
      return reply({ error: "The invitation link is invalid." }, 400);
    }
    const inviteToken = new URL(inviteUrl).searchParams.get("invite");
    if (!inviteToken || !/^[a-f0-9]{64}$/i.test(inviteToken)) return reply({ error: "The invitation link is invalid." }, 400);

    const message = `Hey ${name} 💛

${note}

I found BIT — Becoming Intentional Together. It is a space for us to practice listening, reflect before we respond, and build better communication together. There is no pressure; I want us both to choose it freely. Want to explore it with me?

Tap this personal invitation link to join our shared BIT space:
${inviteUrl}

“Better Communication. Brighter Tomorrows.”`;

    const result = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: fromEmail,
        to: [email],
        subject: "Your invitation to BIT — Becoming Intentional Together",
        text: message,
      }),
    });
    const response = await result.json().catch(() => ({}));
    if (!result.ok) {
      console.error("Resend delivery failed:", result.status, response);
      return reply({ error: "The email service could not send the invitation. Check the email service setup and try again." }, 502);
    }
    return reply({ ok: true, message: "Invitation email sent.", id: response.id || null }, 200);
  } catch (error) {
    console.error("send-bit-invite failed:", error);
    return reply({ error: "BIT could not send the invitation. Please try again." }, 500);
  }
});

function reply(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
