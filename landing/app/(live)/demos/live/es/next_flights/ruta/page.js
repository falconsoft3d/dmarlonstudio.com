"use client";
// Generado por DMarlon Studio a partir de la pantalla «Ruta». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "../_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "../_lib/dms";

export default function RutaPage() {
  useApp();
  const router = useRouter();
  const arg = app.arg("Ruta");
  if (arg === undefined) return <DmsMissing router={router} />;
  return (
    <DmsScreen
      title={`${arg.corto}`}
      back={true}
      actions={[{ icon: "refresh", badge: null, onClick: async () => { app.analizar(arg); } }]}
    >
      <div className="col st" style={{ gap: 12, padding: 16 }}>
        <div className="card" style={{ padding: 14 }}>
          <div className="col st" style={{ gap: 4 }}>
            <h4 className="t-titleMedium">{`${arg.titulo}`}</h4>
            <p className="t-bodySmall">{`${arg.periodo}`}</p>
            <h3 className="t-titleLarge" style={{ color: "var(--primary)" }}>{`${arg.resumen}`}</h3>
            <p className="t-bodyMedium">{`${arg.detalle}`}</p>
            <p className="t-bodySmall">{`${arg.minimo}`}</p>
            <span className="t-labelSmall">{`${arg.cuando}`}</span>
          </div>
        </div>
        <h4 className="t-titleSmall">{`El precio de cada día (toque un día para comprarlo)`}</h4>
        <DmsCanvas aspect={3.2} paint={(ctx, w, h) => { app.dibujarDias(ctx, w, h, arg); }} onTap={async (x, y) => { app.tocarDia(x, y, arg); }} />
        <h4 className="t-titleSmall">{`Lo más barato de cada aerolínea`}</h4>
        <div className="card" style={{ padding: 4 }}>
          <div className="list sep">
            {(arg.mejores).map((b, i) => (
              <div className="item" key={i}>
                <div className="tile tap" onClick={async () => { app.comprar(b.url); }}><span className="ms tile-icon">flight_takeoff</span><div className="tile-text"><div className="tile-title">{`${b.nombre}`}</div><div className="tile-sub">{`${b.detalle}`}</div></div><span className="tile-trail">{`${b.precio}`}</span></div>
              </div>
            ))}
            {(arg.mejores).length === 0 && <p className="empty">{`Sin precios para esas fechas`}</p>}
          </div>
        </div>
        <h4 className="t-titleSmall">{`Cómo cambia el mejor precio`}</h4>
        <DmsCanvas aspect={4} paint={(ctx, w, h) => { app.dibujarHistoria(ctx, w, h, arg); }} />
        <button type="button" className="btn btn-outlined" onClick={async (e) => { e.stopPropagation(); app.quitar(arg); router.back(); }}><span className="ms">delete</span>{`Quitar la ruta`}</button>
      </div>
    </DmsScreen>
  );
}
