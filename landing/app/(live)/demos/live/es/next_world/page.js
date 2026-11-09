"use client";
// Generado por DMarlon Studio a partir de la pantalla «Mapa». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "./_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "./_lib/dms";

export default function MapaPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`El mundo en directo`}
      back={false}
      actions={[{ icon: "refresh", badge: null, onClick: async () => { app.actualizar(); } }]}
    >
      <div className="col st" style={{ gap: 10, padding: 12 }}>
        <div className="row wrap" style={{ gap: 8, alignItems: "center" }}>
          <button type="button" className={"chip" + ((app.capas.plane) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.capa('plane'); }}><span className="ms">flight</span>{`Aviones · ${app.nAviones}`}</button>
          <button type="button" className={"chip" + ((app.capas.ship) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.capa('ship'); }}><span className="ms">directions_boat</span>{`Barcos · ${app.nBarcos}`}</button>
          <button type="button" className={"chip" + ((app.capas.train) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.capa('train'); }}><span className="ms">train</span>{`Trenes · ${app.nTrenes}`}</button>
        </div>
        <div className="row wrap" style={{ gap: 6, alignItems: "center" }}>
          <button type="button" className={"chip" + ((app.region == 'world') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('world'); }}>{`Mundo`}</button>
          <button type="button" className={"chip" + ((app.region == 'europe') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('europe'); }}>{`Europa`}</button>
          <button type="button" className={"chip" + ((app.region == 'namerica') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('namerica'); }}>{`Norteamérica`}</button>
          <button type="button" className={"chip" + ((app.region == 'samerica') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('samerica'); }}>{`Sudamérica`}</button>
          <button type="button" className={"chip" + ((app.region == 'asia') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('asia'); }}>{`Asia`}</button>
          <button type="button" className={"chip" + ((app.region == 'baltic') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('baltic'); }}>{`Mar Báltico`}</button>
          <button type="button" className={"chip" + ((app.region == 'spain') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('spain'); }}>{`España`}</button>
        </div>
        <DmsCanvas aspect={1.6} paint={(ctx, w, h) => { app.dibujar(ctx, w, h); }} onTap={async (x, y) => { app.tocar(x, y); }} />
        <div className="row" style={{ gap: 4, alignItems: "center" }}>
          <div className="grow" style={{ flex: 1 }}>
            <span className="t-labelSmall">{`${app.estado}`}</span>
          </div>
          <button className="icon-btn" type="button" title="Alejar" aria-label="Alejar" onClick={async (e) => { e.stopPropagation(); app.alejar(); }}><span className="ms">zoom_out</span></button>
          <button className="icon-btn" type="button" title="Acercar" aria-label="Acercar" onClick={async (e) => { e.stopPropagation(); app.acercar(); }}><span className="ms">zoom_in</span></button>
        </div>
        {(app.sel != null) && (
          <div className="card" style={{ padding: 14 }}>
          <div className="col st" style={{ gap: 4 }}>
            <div className="row" style={{ gap: 10, alignItems: "center" }}>
              <span className="ms" style={{ fontSize: 24, color: app.selColor }}>{app.selIcono}</span>
              <div className="grow" style={{ flex: 1 }}>
                <h4 className="t-titleMedium">{`${app.selTitulo}`}</h4>
              </div>
              <button className="icon-btn" type="button" title="Seguirlo en el mapa" aria-label="Seguirlo en el mapa" onClick={async (e) => { e.stopPropagation(); app.alternarSeguir(); }}><span className="ms">{app.seguir ? "gps_fixed" : "gps_not_fixed"}</span></button>
              <button className="icon-btn" type="button" title="Cerrar" aria-label="Cerrar" onClick={async (e) => { e.stopPropagation(); app.cerrar(); }}><span className="ms">close</span></button>
            </div>
            <p className="t-bodyMedium">{`${app.selLinea(0)}`}</p>
            <p className="t-bodySmall">{`${app.selLinea(1)}`}</p>
            <p className="t-bodySmall">{`${app.selLinea(2)}`}</p>
            <p className="t-bodySmall">{`${app.selLinea(3)}`}</p>
          </div>
        </div>
        )}
        <span className="t-labelSmall">{`Toque un avión, un barco o un tren para ver sus datos; toque el mar o la tierra para centrar el mapa ahí.`}</span>
      </div>
    </DmsScreen>
  );
}
