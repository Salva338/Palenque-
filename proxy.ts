import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// Rutas que se pueden abrir sin haber iniciado sesión.
const PUBLICAS = ["/login"];

/**
 * Antes de cada página: renueva la sesión de Supabase (cookies) y,
 * si no hay usuario, manda al login.
 */
export async function proxy(request: NextRequest) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();
  const esPublica = PUBLICAS.some((p) => request.nextUrl.pathname.startsWith(p));

  // Sin Supabase configurado no hay sesión posible: se muestra el login, que explica qué falta.
  if (!url || !key) {
    return esPublica ? NextResponse.next() : NextResponse.redirect(new URL("/login", request.url));
  }

  let response = NextResponse.next({ request });
  const supabase = createServerClient(url, key, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        for (const { name, value } of cookiesToSet) request.cookies.set(name, value);
        response = NextResponse.next({ request });
        for (const { name, value, options } of cookiesToSet) response.cookies.set(name, value, options);
      },
    },
  });

  // getUser() valida la sesión contra Supabase (no confía solo en la cookie).
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user && !esPublica) {
    const destino = new URL("/login", request.url);
    return NextResponse.redirect(destino);
  }
  if (user && esPublica) {
    return NextResponse.redirect(new URL("/", request.url));
  }
  return response;
}

export const config = {
  // Todo menos archivos estáticos e imágenes.
  matcher: ["/((?!_next/static|_next/image|icon.png|apple-touch-icon.png|logo.png|.*\\.(?:png|jpg|jpeg|svg|webp|ico)$).*)"],
};
