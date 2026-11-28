
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Método no permitido." }, 405);
  }

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!url || !serviceRoleKey) {
      return jsonResponse(
        { error: "Configuración del servidor incompleta." },
        500,
      );
    }

    // Privileged server-side client. Never use this key in Flutter.
    const admin = createClient(url, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Verify the signed-in administrator's JWT.
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");

    if (!token || token === authHeader) {
      return jsonResponse({ error: "Sesión requerida." }, 401);
    }

    const { data: authData, error: authError } =
      await admin.auth.getUser(token);

    if (authError || !authData.user) {
      return jsonResponse({ error: "Sesión inválida." }, 401);
    }

    // Check the role in the database, not in user-provided metadata.
    const { data: profile, error: roleError } = await admin
      .from("profiles")
      .select("role")
      .eq("id", authData.user.id)
      .single();

    if (roleError || profile?.role !== "admin") {
      return jsonResponse(
        { error: "No tienes permisos para registrar usuarios." },
        403,
      );
    }

    let body: Record<string, unknown>;

    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: "Datos inválidos." }, 400);
    }

    const fullName = String(body.fullName ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const department = String(body.department ?? "").trim();
    const role = String(body.role ?? "").trim();

    const allowedRoles = [
      "admin",
      "requester",
      "secretary",
      "staff",
    ];

    if (
      fullName.length < 3 ||
      fullName.length > 150 ||
      department.length < 2 ||
      department.length > 150 ||
      email.length > 254 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
      !allowedRoles.includes(role)
    ) {
      return jsonResponse(
        { error: "Revisa los datos del usuario." },
        400,
      );
    }

    // Create an Auth account and send an invitation email.
    const { data: invitation, error: invitationError } =
  await admin.auth.admin.inviteUserByEmail(email, {
    data: { full_name: fullName },
    redirectTo: "com.cyd.itmerida://auth-callback/",
  });

    if (invitationError || !invitation.user) {
      console.error("Invitation error:", invitationError);
      return jsonResponse(
        { error: "No se pudo enviar la invitación." },
        400,
      );
    }

    const userId = invitation.user.id;

    // Register the institutional profile using the same Auth UUID.
    const { error: profileError } = await admin
      .from("profiles")
      .insert({
        id: userId,
        full_name: fullName,
        department: department,
        role: role,
      });

    if (profileError) {
      // Compensating action if profile creation fails.
      const { error: rollbackError } =
        await admin.auth.admin.deleteUser(userId);

      console.error("Profile creation error:", profileError);

      if (rollbackError) {
        console.error("Rollback error:", rollbackError);
      }

      return jsonResponse(
        {
          error: "No se pudo completar el registro del usuario.",
        },
        500,
      );
    }

    return jsonResponse(
      {
        success: true,
        userId: userId,
        message: "Usuario invitado correctamente.",
      },
      201,
    );
  } catch (error) {
    console.error("Unexpected user creation error:", error);

    return jsonResponse(
      { error: "Error interno al registrar el usuario." },
      500,
    );
  }
});
