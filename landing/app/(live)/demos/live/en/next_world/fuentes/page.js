"use client";
// Generado por DMarlon Studio a partir de la pantalla «Fuentes». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "../_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "../_lib/dms";

export default function FuentesPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`Sources`}
      back={false}
      actions={[]}
    >
      <div className="col st" style={{ gap: 12, padding: 12 }}>
        <div className="list sep">
          {(app.fuentes).map((f, i) => (
            <div className="item" key={i}>
              <div className="tile"><span className="avatar" style={{ background: f.color }}><span className="ms">{f.icon}</span></span><div className="tile-text"><div className="tile-title">{`${f.name}`}</div><div className="tile-sub">{`${f.detail}`}</div></div><span className="tile-trail">{`${f.n}`}</span></div>
            </div>
          ))}
        </div>
        <div className="card" style={{ padding: 16 }}>
          <div className="col st" style={{ gap: 8 }}>
            <h4 className="t-titleMedium">{`How it works`}</h4>
            <p className="t-bodyMedium">{`The website asks its own Next.js server for the data every 30 seconds. The server downloads it from the public APIs, merges it and keeps it in memory for a while: the browser never talks to them and no keys are needed.`}</p>
            <p className="t-bodySmall">{`Planes: OpenSky Network, the whole world (without an account, every 15 minutes; with OPENSKY_CLIENT_ID and OPENSKY_CLIENT_SECRET, every 90 seconds) or adsb.lol. Between readings, each plane moves along its heading at its speed.`}</p>
            <p className="t-bodySmall">{`Ships: the Baltic Sea AIS from Fintraffic (Digitraffic). Trains: Renfe Cercanías (Spain) and VR (Finland). The map: Natural Earth.`}</p>
          </div>
        </div>
      </div>
    </DmsScreen>
  );
}
