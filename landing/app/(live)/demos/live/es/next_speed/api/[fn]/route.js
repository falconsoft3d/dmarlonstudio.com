// Generado por DMarlon Studio: las funciones que exporta lib/server.js, como
// API (POST o GET /api/<función>). No lo edite.
import * as server from "../../_lib/server";

export const dynamic = "force-dynamic";

async function call(request, params, args) {
  const { fn } = await params;
  const f = server[fn];
  if (typeof f !== "function" || fn.startsWith("_")) {
    return Response.json({ error: "No existe: " + fn }, { status: 404 });
  }
  try {
    const out = await f(args, request);
    return out instanceof Response ? out : Response.json(out === undefined ? null : out);
  } catch (e) {
    console.error(e);
    return Response.json({ error: String((e && e.message) || e) }, { status: 500 });
  }
}

const query = (request) => Object.fromEntries(new URL(request.url).searchParams);

export function GET(request, { params }) {
  return call(request, params, query(request));
}

export async function POST(request, { params }) {
  const json = (request.headers.get("content-type") || "").includes("application/json");
  const args = json ? await request.json().catch(() => ({})) : query(request);
  return call(request, params, args ?? {});
}
