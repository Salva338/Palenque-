/**
 * Pruebas de permisos contra el proyecto palenque-test (secciones 5.3 y 14.5).
 * Crea dos organizaciones con un usuario por rol, prueba qué puede ver y hacer
 * cada uno entrando como ese usuario, y al final borra todo lo que creó.
 */
import { randomUUID } from "node:crypto";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { assertTestEnvironment } from "@/lib/test/assert-test-env";

const { url } = assertTestEnvironment();
// trim(): al pegar una llave en GitHub es fácil que se cuele un espacio o un salto de línea,
// y eso rompe el encabezado HTTP ("invalid header value").
const publishable = (process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? "").trim();
const secret = (process.env.SUPABASE_SECRET_KEY ?? "").trim();
if (!publishable || !secret) throw new Error("Faltan las llaves del proyecto de pruebas.");
for (const [nombre, valor, prefijo] of [
  ["TEST_SUPABASE_PUBLISHABLE_KEY", publishable, "sb_publishable_"],
  ["TEST_SUPABASE_SECRET_KEY", secret, "sb_secret_"],
] as const) {
  if (!valor.startsWith(prefijo) || /\s/.test(valor)) {
    throw new Error(`El secreto ${nombre} no tiene el formato esperado (tiene que empezar con ${prefijo} y no tener espacios).`);
  }
}

const sinSesion = { auth: { persistSession: false, autoRefreshToken: false } };
const admin = createClient(url, secret, sinSesion);

type Rol = "dueno" | "encargado" | "petisero" | "vet" | "herrero";
const ROLES: Rol[] = ["dueno", "encargado", "petisero", "vet", "herrero"];
const corrida = randomUUID().slice(0, 8);
const password = `Prueba-${randomUUID()}`;

const usuariosCreados: string[] = [];
const orgsCreadas: string[] = [];
const clientes = {} as Record<Rol, SupabaseClient> & { ajeno: SupabaseClient };
const ids = {} as Record<Rol | "ajeno", string>;

let orgA = "";
let orgB = "";
let caballoA = "";
let caballoB = "";
let eventoA = "";

async function crearUsuario(etiqueta: string): Promise<{ id: string; cliente: SupabaseClient }> {
  const email = `rls-${corrida}-${etiqueta}@example.com`;
  const { data, error } = await admin.auth.admin.createUser({ email, password, email_confirm: true });
  if (error || !data.user) throw new Error(`No se pudo crear el usuario ${etiqueta}: ${error?.message}`);
  usuariosCreados.push(data.user.id);
  const cliente = createClient(url, publishable, sinSesion);
  const { error: e2 } = await cliente.auth.signInWithPassword({ email, password });
  if (e2) throw new Error(`No se pudo iniciar sesión como ${etiqueta}: ${e2.message}`);
  return { id: data.user.id, cliente };
}

async function ok<T>(p: PromiseLike<{ data: T; error: { message: string } | null }>): Promise<NonNullable<T>> {
  const { data, error } = await p;
  if (error) throw new Error(error.message);
  if (data === null || data === undefined) throw new Error("La consulta no devolvió datos.");
  return data;
}

beforeAll(async () => {
  const [a] = await ok(admin.from("organizations").insert({ name: `RLS A ${corrida}` }).select("id"));
  const [b] = await ok(admin.from("organizations").insert({ name: `RLS B ${corrida}` }).select("id"));
  orgA = a.id;
  orgB = b.id;
  orgsCreadas.push(orgA, orgB);

  for (const rol of ROLES) {
    const u = await crearUsuario(rol);
    ids[rol] = u.id;
    clientes[rol] = u.cliente;
    await ok(admin.from("memberships").insert({ user_id: u.id, org_id: orgA, role: rol, display_name: rol }));
  }
  const ajeno = await crearUsuario("ajeno");
  ids.ajeno = ajeno.id;
  clientes.ajeno = ajeno.cliente;
  await ok(admin.from("memberships").insert({ user_id: ajeno.id, org_id: orgB, role: "dueno", display_name: "ajeno" }));

  const [hA] = await ok(
    admin.from("horses").insert({ org_id: orgA, number: 4, name: "Tango", sex: "yegua" }).select("id"),
  );
  const [hB] = await ok(
    admin.from("horses").insert({ org_id: orgB, number: 1, name: "Secreto", sex: "padrillo" }).select("id"),
  );
  caballoA = hA.id;
  caballoB = hB.id;

  const [ev] = await ok(
    admin
      .from("events")
      .insert({ org_id: orgA, horse_id: caballoA, type: "vet", title: "Control", occurred_on: "2026-11-20" })
      .select("id"),
  );
  eventoA = ev.id;
  await ok(admin.from("event_costs").insert({ event_id: eventoA, org_id: orgA, amount: 15000 }));
  await ok(
    admin.from("events").insert({ org_id: orgB, horse_id: caballoB, type: "nota", title: "Privado", occurred_on: "2026-11-20" }),
  );
  await ok(
    admin.from("whatsapp_messages").insert({
      wa_message_id: `wamid.${corrida}`,
      org_id: orgA,
      from_phone: "+5491100000000",
      direction: "in",
      msg_type: "text",
      body: "el 4 no comió",
      raw: {},
    }),
  );
}, 120_000);

afterAll(async () => {
  await admin.from("whatsapp_messages").delete().eq("wa_message_id", `wamid.${corrida}`);
  for (const org of orgsCreadas) await admin.from("organizations").delete().eq("id", org);
  for (const id of usuariosCreados) await admin.auth.admin.deleteUser(id);
}, 120_000);

describe("RLS activo en todas las tablas", () => {
  it("no hay ninguna tabla pública sin RLS", async () => {
    const data = await ok(admin.rpc("tables_without_rls"));
    expect(data).toEqual([]);
  });

  it("un usuario común no puede llamar a la función de auditoría", async () => {
    const { error } = await clientes.dueno.rpc("tables_without_rls");
    expect(error).not.toBeNull();
  });
});

describe("(1) costos: solo dueño y encargado", () => {
  it.each(["dueno", "encargado"] as Rol[])("%s ve el costo", async (rol) => {
    const data = await ok(clientes[rol].from("event_costs").select("amount").eq("event_id", eventoA));
    expect(data).toHaveLength(1);
  });

  it.each(["petisero", "vet", "herrero"] as Rol[])("%s NO ve ningún costo (consulta directa)", async (rol) => {
    const data = await ok(clientes[rol].from("event_costs").select("*"));
    expect(data).toEqual([]);
  });

  it("el petisero no puede cargar un costo", async () => {
    const { error } = await clientes.petisero
      .from("event_costs")
      .upsert({ event_id: eventoA, org_id: orgA, amount: 1 });
    expect(error).not.toBeNull();
  });
});

describe("(2) aislamiento entre organizaciones", () => {
  it("el usuario de la org B no ve nada de la org A", async () => {
    for (const tabla of ["horses", "events", "memberships", "care_rules", "org_settings"]) {
      const data = await ok(clientes.ajeno.from(tabla).select("org_id").eq("org_id", orgA));
      expect(data, `tabla ${tabla}`).toEqual([]);
    }
    const orgs = await ok(clientes.ajeno.from("organizations").select("id"));
    expect(orgs.map((o: { id: string }) => o.id)).toEqual([orgB]);
  });

  it("el dueño de la org A no ve el caballo de la org B", async () => {
    const data = await ok(clientes.dueno.from("horses").select("id").eq("id", caballoB));
    expect(data).toEqual([]);
  });

  it("nadie de la org A puede cargar un evento en un caballo de la org B", async () => {
    const { error } = await clientes.dueno.from("events").insert({
      org_id: orgA,
      horse_id: caballoB,
      type: "nota",
      title: "trampa",
      occurred_on: "2026-11-20",
      created_by: ids.dueno,
    });
    expect(error).not.toBeNull();
  });
});

describe("(3) herrero: solo carga herrados", () => {
  it("puede cargar un evento de herrería", async () => {
    const { error } = await clientes.herrero.from("events").insert({
      org_id: orgA,
      horse_id: caballoA,
      type: "herreria",
      title: "Herrado",
      occurred_on: "2026-11-21",
      created_by: ids.herrero,
    });
    expect(error).toBeNull();
  });

  it("NO puede cargar un evento de otro tipo", async () => {
    const { error } = await clientes.herrero.from("events").insert({
      org_id: orgA,
      horse_id: caballoA,
      type: "vet",
      title: "Control",
      occurred_on: "2026-11-21",
      created_by: ids.herrero,
    });
    expect(error).not.toBeNull();
  });
});

describe("(4) petisero: carga pero no edita ni borra", () => {
  it("puede cargar un evento", async () => {
    const { error } = await clientes.petisero.from("events").insert({
      org_id: orgA,
      horse_id: caballoA,
      type: "alimento",
      title: "No comió",
      occurred_on: "2026-11-22",
      created_by: ids.petisero,
    });
    expect(error).toBeNull();
  });

  it("NO puede editar un evento", async () => {
    const data = await ok(
      clientes.petisero.from("events").update({ title: "cambiado" }).eq("id", eventoA).select("id"),
    );
    expect(data).toEqual([]);
    const [fila] = await ok(admin.from("events").select("title").eq("id", eventoA));
    expect(fila.title).toBe("Control");
  });

  it("NO puede borrar un evento", async () => {
    await clientes.petisero.from("events").delete().eq("id", eventoA);
    const data = await ok(admin.from("events").select("id").eq("id", eventoA));
    expect(data).toHaveLength(1);
  });

  it("NO puede cargar un evento a nombre de otra persona", async () => {
    const { error } = await clientes.petisero.from("events").insert({
      org_id: orgA,
      horse_id: caballoA,
      type: "nota",
      title: "Suplantación",
      occurred_on: "2026-11-22",
      created_by: ids.dueno,
    });
    expect(error).not.toBeNull();
  });
});

describe("(5) nadie del lado del cliente lee los mensajes de WhatsApp", () => {
  it.each([...ROLES, "ajeno"] as (Rol | "ajeno")[])("%s no ve whatsapp_messages", async (rol) => {
    const data = await ok(clientes[rol].from("whatsapp_messages").select("id"));
    expect(data).toEqual([]);
  });
});

describe("caballos: matriz 5.2", () => {
  it("la veterinaria puede cambiar el estado", async () => {
    const data = await ok(
      clientes.vet.from("horses").update({ status: "lesionado" }).eq("id", caballoA).select("status"),
    );
    expect(data).toEqual([{ status: "lesionado" }]);
  });

  it("la veterinaria NO puede cambiar otros datos del caballo", async () => {
    const { error } = await clientes.vet.from("horses").update({ name: "Otro" }).eq("id", caballoA);
    expect(error).not.toBeNull();
  });

  it("el petisero NO puede crear caballos", async () => {
    const { error } = await clientes.petisero
      .from("horses")
      .insert({ org_id: orgA, number: 99, name: "Nuevo", sex: "yegua" });
    expect(error).not.toBeNull();
  });

  it("el encargado NO puede borrar caballos (solo el dueño)", async () => {
    await clientes.encargado.from("horses").delete().eq("id", caballoA);
    const data = await ok(admin.from("horses").select("id").eq("id", caballoA));
    expect(data).toHaveLength(1);
  });
});

describe("organización nueva", () => {
  it("se crea sola con sus umbrales y las 5 reglas de agenda", async () => {
    const reglas = await ok(clientes.dueno.from("care_rules").select("key").eq("org_id", orgA));
    expect(reglas.map((r: { key: string }) => r.key).sort()).toEqual(["aie", "dent", "desp", "herr", "vac"]);
    const ajustes = await ok(clientes.dueno.from("org_settings").select("load_chukkers_14d").eq("org_id", orgA));
    expect(ajustes).toEqual([{ load_chukkers_14d: 4 }]);
  });
});
