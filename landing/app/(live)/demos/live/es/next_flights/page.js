"use client";
// Generado por DMarlon Studio a partir de la pantalla «Rutas». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "./_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "./_lib/dms";

export default function RutasPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`Buscador de vuelos`}
      back={false}
      actions={[{ icon: "add", badge: null, onClick: async () => { app.go(router, 'Nueva'); } }, { icon: "refresh", badge: null, onClick: async () => { app.analizarTodas(); } }]}
    >
      <div className="col st" style={{ gap: 10, padding: 16 }}>
        {(app.aviso) && (
          <div className="card" style={{ padding: 12, background: "var(--primary-container)" }}>
          <div className="row" style={{ gap: 10, alignItems: "center" }}>
            <span className="ms" style={{ fontSize: 24 }}>notifications</span>
            <div className="grow" style={{ flex: 1 }}>
              <p className="t-bodyLarge" style={{ fontWeight: 700 }}>{`${app.aviso}`}</p>
            </div>
            <button className="icon-btn" type="button" title="Cerrar" aria-label="Cerrar" onClick={async (e) => { e.stopPropagation(); app.cerrarAviso(); }}><span className="ms">close</span></button>
          </div>
        </div>
        )}
        <span className="t-labelSmall">{`${app.modo} · ${app.proximo}`}</span>
        <div className="list sep">
          {(app.rutas).map((r, i) => (
            <div className="item" key={i}>
              <div className="tile tap" onClick={async () => { app.go(router, 'Ruta', r); }}><span className="avatar" style={{ background: "var(--primary)" }}><span className="ms">flight</span></span><div className="tile-text"><div className="tile-title">{`${r.corto}`}</div><div className="tile-sub">{`${r.sub}`}</div></div><span className="tile-trail">{`${r.precioTexto}`}</span></div>
            </div>
          ))}
          {(app.rutas).length === 0 && <p className="empty">{`Añada una ruta con el botón + para vigilar sus precios.`}</p>}
        </div>
        <span className="t-labelSmall">{`Las rutas se guardan en este navegador. El servidor consulta los precios de todas las aerolíneas y agencias de Aviasales con su token, que nunca llega aquí.`}</span>
      </div>
    </DmsScreen>
  );
}
