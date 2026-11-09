"use client";
// Generado por DMarlon Studio a partir de la pantalla «Nueva». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "../_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "../_lib/dms";

export default function NuevaPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`Nueva ruta`}
      back={true}
      actions={[]}
    >
      <div className="col st" style={{ gap: 12, padding: 16 }}>
        <label className="field" onClick={(e) => e.stopPropagation()}><span className="field-label">{`Origen`}</span><span className="field-box"><input type="text" placeholder={`Madrid o MAD`} value={app.f.origen ?? ""} onChange={(e) => { app.f.origen = e.target.value; app.notify(); }} /></span></label>
        <label className="field" onClick={(e) => e.stopPropagation()}><span className="field-label">{`Destino`}</span><span className="field-box"><input type="text" placeholder={`La Habana o HAV`} value={app.f.destino ?? ""} onChange={(e) => { app.f.destino = e.target.value; app.notify(); }} /></span></label>
        <div className="row" style={{ gap: 12, alignItems: "center" }}>
          <div className="grow" style={{ flex: 1 }}>
            <label className="field" onClick={(e) => e.stopPropagation()}><span className="field-label">{`Ida`}</span><span className="field-box"><input type="text" placeholder={`2026-12 o 2026-12-20`} value={app.f.ida ?? ""} onChange={(e) => { app.f.ida = e.target.value; app.notify(); }} /></span></label>
          </div>
          <div className="grow" style={{ flex: 1 }}>
            <label className="field" onClick={(e) => e.stopPropagation()}><span className="field-label">{`Vuelta`}</span><span className="field-box"><input type="text" placeholder={`Vacía: solo ida`} value={app.f.vuelta ?? ""} onChange={(e) => { app.f.vuelta = e.target.value; app.notify(); }} /></span></label>
          </div>
        </div>
        <label className="field" onClick={(e) => e.stopPropagation()}><span className="field-label">{`Avisar si baja de`}</span><span className="field-box"><input type="number" placeholder={`Opcional, en la moneda elegida`} value={app.f.aviso ?? ""} onChange={(e) => { app.f.aviso = e.target.value; app.notify(); }} /></span></label>
        <div className="row wrap" style={{ gap: 8, alignItems: "center" }}>
          <button type="button" className={"chip" + ((app.f.moneda == 'EUR') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.moneda('EUR'); }}>{`EUR`}</button>
          <button type="button" className={"chip" + ((app.f.moneda == 'USD') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.moneda('USD'); }}>{`USD`}</button>
          <button type="button" className={"chip" + ((app.f.moneda == 'GBP') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.moneda('GBP'); }}>{`GBP`}</button>
          <button type="button" className={"chip" + ((app.f.moneda == 'MXN') ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.moneda('MXN'); }}>{`MXN`}</button>
          <button type="button" className={"chip" + ((app.f.directo) ? " on" : "")} onClick={async (e) => { e.stopPropagation(); app.alternarDirecto(); }}><span className="ms">flight_takeoff</span>{`Solo directos`}</button>
        </div>
        {(app.error) && (
          <p className="t-bodyLarge" style={{ color: "#C2453B" }}>{`${app.error}`}</p>
        )}
        <button type="button" className="btn btn-filled" onClick={async (e) => { e.stopPropagation(); if (await app.anadir()) { router.back(); } }}><span className="ms">search</span>{`Añadir y analizar`}</button>
      </div>
    </DmsScreen>
  );
}
