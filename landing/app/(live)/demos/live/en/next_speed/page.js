"use client";
// Generado por DMarlon Studio a partir de la pantalla «Prueba». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "./_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "./_lib/dms";

export default function PruebaPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`Internet Speed Test`}
      back={false}
      actions={[]}
    >
      <div className="col st" style={{ gap: 12, padding: 16 }}>
        <DmsCanvas aspect={1.7} paint={(ctx, w, h) => { app.dibujar(ctx, w, h); }} />
        <p className="t-bodyMedium" style={{ textAlign: "center" }}>{`${app.estado}`}</p>
        <div className="row" style={{ gap: 10, alignItems: "flex-start" }}>
          <div className="grow" style={{ flex: 1 }}>
            <div className="card" style={{ padding: 14 }}>
              <div className="col" style={{ gap: 4, alignItems: "flex-start" }}>
                <div className="row" style={{ gap: 6, alignItems: "center" }}>
                  <span className="ms" style={{ fontSize: 18, color: "var(--primary)" }}>timer</span>
                  <span className="t-labelLarge">{`Ping`}</span>
                </div>
                <h2 className="t-headlineSmall" style={{ fontWeight: 700 }}>{`${app.pingTexto}`}</h2>
                <span className="t-labelSmall">{`ms · ${app.jitterTexto}`}</span>
              </div>
            </div>
          </div>
          <div className="grow" style={{ flex: 1 }}>
            <div className="card" style={{ padding: 14 }}>
              <div className="col" style={{ gap: 4, alignItems: "flex-start" }}>
                <div className="row" style={{ gap: 6, alignItems: "center" }}>
                  <span className="ms" style={{ fontSize: 18, color: "var(--primary)" }}>download</span>
                  <span className="t-labelLarge">{`Download`}</span>
                </div>
                <h2 className="t-headlineSmall" style={{ fontWeight: 700 }}>{`${app.bajadaTexto}`}</h2>
                <span className="t-labelSmall">{`Mbps`}</span>
              </div>
            </div>
          </div>
          <div className="grow" style={{ flex: 1 }}>
            <div className="card" style={{ padding: 14 }}>
              <div className="col" style={{ gap: 4, alignItems: "flex-start" }}>
                <div className="row" style={{ gap: 6, alignItems: "center" }}>
                  <span className="ms" style={{ fontSize: 18, color: "var(--primary)" }}>upload</span>
                  <span className="t-labelLarge">{`Upload`}</span>
                </div>
                <h2 className="t-headlineSmall" style={{ fontWeight: 700 }}>{`${app.subidaTexto}`}</h2>
                <span className="t-labelSmall">{`Mbps`}</span>
              </div>
            </div>
          </div>
        </div>
        <button type="button" className="btn btn-filled" onClick={async (e) => { e.stopPropagation(); app.alternar(); }}><span className="ms">{app.botonIcono}</span>{`${app.boton}`}</button>
        {(app.hayUsos) && (
          <div className="card" style={{ padding: 14 }}>
          <div className="col st" style={{ gap: 6 }}>
            <h4 className="t-titleMedium">{`What it is good enough for`}</h4>
            <div className="list">
              {(app.usos).map((u, i) => (
                <div className="item" key={i}>
                  <div className="tile"><span className="avatar" style={{ background: u.color }}><span className="ms">{u.icon}</span></span><div className="tile-text"><div className="tile-title">{`${u.what}`}</div><div className="tile-sub">{`${u.need}`}</div></div></div>
                </div>
              ))}
            </div>
          </div>
        </div>
        )}
        <span className="t-labelSmall">{`${app.servidor}`}</span>
        <span className="t-labelSmall">{`The measurement is between your browser and this website's server: it also depends on the Wi-Fi, on the rest of the household and on where the server is.`}</span>
      </div>
    </DmsScreen>
  );
}
