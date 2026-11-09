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
      title={`Live World Map`}
      back={false}
      actions={[{ icon: "refresh", badge: null, onClick: async () => { app.actualizar(); } }]}
    >
      <div className="col st" style={{ gap: 10, padding: 12 }}>
        <div className="row wrap" style={{ gap: 8, alignItems: "center" }}>
          <button type="button" className={"chip" + ((app.capas.plane) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.capa('plane'); }}><span className="ms">flight</span>{`Planes · ${app.nAviones}`}</button>
          <button type="button" className={"chip" + ((app.capas.ship) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.capa('ship'); }}><span className="ms">directions_boat</span>{`Ships · ${app.nBarcos}`}</button>
          <button type="button" className={"chip" + ((app.capas.train) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.capa('train'); }}><span className="ms">train</span>{`Trains · ${app.nTrenes}`}</button>
        </div>
        <div className="row wrap" style={{ gap: 6, alignItems: "center" }}>
          <button type="button" className={"chip" + ((app.region == 'world') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('world'); }}>{`World`}</button>
          <button type="button" className={"chip" + ((app.region == 'europe') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('europe'); }}>{`Europe`}</button>
          <button type="button" className={"chip" + ((app.region == 'namerica') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('namerica'); }}>{`North America`}</button>
          <button type="button" className={"chip" + ((app.region == 'samerica') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('samerica'); }}>{`South America`}</button>
          <button type="button" className={"chip" + ((app.region == 'asia') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('asia'); }}>{`Asia`}</button>
          <button type="button" className={"chip" + ((app.region == 'baltic') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('baltic'); }}>{`Baltic Sea`}</button>
          <button type="button" className={"chip" + ((app.region == 'spain') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.zona('spain'); }}>{`Spain`}</button>
        </div>
        <DmsCanvas aspect={1.6} paint={(ctx, w, h) => { app.dibujar(ctx, w, h); }} onTap={async (x, y) => { app.tocar(x, y); }} />
        <div className="row" style={{ gap: 4, alignItems: "center" }}>
          <div className="grow" style={{ flex: 1 }}>
            <span className="t-labelSmall">{`${app.estado}`}</span>
          </div>
          <button className="icon-btn" type="button" title="Zoom out" aria-label="Zoom out" onClick={async (e) => { e.stopPropagation(); app.alejar(); }}><span className="ms">zoom_out</span></button>
          <button className="icon-btn" type="button" title="Zoom in" aria-label="Zoom in" onClick={async (e) => { e.stopPropagation(); app.acercar(); }}><span className="ms">zoom_in</span></button>
        </div>
        {(app.sel != null) && (
          <div className="card" style={{ padding: 14 }}>
          <div className="col st" style={{ gap: 4 }}>
            <div className="row" style={{ gap: 10, alignItems: "center" }}>
              <span className="ms" style={{ fontSize: 24, color: app.selColor }}>{app.selIcono}</span>
              <div className="grow" style={{ flex: 1 }}>
                <h4 className="t-titleMedium">{`${app.selTitulo}`}</h4>
              </div>
              <button className="icon-btn" type="button" title="Follow it on the map" aria-label="Follow it on the map" onClick={async (e) => { e.stopPropagation(); app.alternarSeguir(); }}><span className="ms">{app.seguir ? "gps_fixed" : "gps_not_fixed"}</span></button>
              <button className="icon-btn" type="button" title="Close" aria-label="Close" onClick={async (e) => { e.stopPropagation(); app.cerrar(); }}><span className="ms">close</span></button>
            </div>
            <p className="t-bodyMedium">{`${app.selLinea(0)}`}</p>
            <p className="t-bodySmall">{`${app.selLinea(1)}`}</p>
            <p className="t-bodySmall">{`${app.selLinea(2)}`}</p>
            <p className="t-bodySmall">{`${app.selLinea(3)}`}</p>
          </div>
        </div>
        )}
        <span className="t-labelSmall">{`Tap a plane, a ship or a train to see its details; tap the sea or the land to center the map there.`}</span>
      </div>
    </DmsScreen>
  );
}
