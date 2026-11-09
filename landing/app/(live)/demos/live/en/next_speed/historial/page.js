"use client";
// Generado por DMarlon Studio a partir de la pantalla «Historial». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "../_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "../_lib/dms";

export default function HistorialPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`History`}
      back={false}
      actions={[]}
    >
      <div className="col st" style={{ gap: 12, padding: 16 }}>
        <p className="t-bodyMedium">{`${app.resumenHistorial}`}</p>
        <div className="list sep">
          {(app.filas).map((f, i) => (
            <div className="item" key={i}>
              <div className="tile"><span className="ms tile-icon">speed</span><div className="tile-text"><div className="tile-title">{`${f.title}`}</div><div className="tile-sub">{`${f.sub}`}</div></div><span className="tile-trail">{`${f.ping}`}</span></div>
            </div>
          ))}
          {(app.filas).length === 0 && <p className="empty">{`Measurements are saved in this browser.`}</p>}
        </div>
        <button type="button" className="btn btn-outlined" onClick={async (e) => { e.stopPropagation(); app.borrar(); }}><span className="ms">delete</span>{`Clear the history`}</button>
      </div>
    </DmsScreen>
  );
}
