import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:dmarlon_studio/code/tk_pascal.dart';
import 'package:dmarlon_studio/code/tk_pascal_run.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String id(String s) => s;

/// Prueba de verdad contra un Odoo: entra (y falla con una contraseña o una
/// base de datos que no existen), descarga, crea sin conexión un cliente y
/// un presupuesto, los envía, comprueba en Odoo que hay uno de cada y que
/// reenviarlos (como si la respuesta se hubiera perdido) no los duplica,
/// envía un cambio del cliente y borra lo que creó. Usa las mismas clases
/// de la aplicación (TOdooClient, TOdooStore y TOdooSync).
const _selfTest = r'''
procedure DmsSelfTest;
var
  Cfg: TJSONObject;
  C: TOdooClient;
  St: TOdooStore;
  Sy: TOdooSync;
  P, O, BP, BB, BB2, K1, K2: TJSONObject;
  L, Prods, Goods, Args, Rows: TJSONArray;
  BR: TJSONData;
  Bid, Bid2, BPid, BI, BX: Integer;
  BErr, BRef, BPRef: string;
  Ref, ORef, Dir, Fails, Pass, Db, Sale1, Sale2, Before: string;
  I, J, Pid, Oid: Integer;

  procedure Check(Ok: Boolean; const What: string);
  begin
    if Ok then WriteLn('ok ', What)
    else
    begin
      WriteLn('FAIL ', What);
      Fails := Fails + ' ' + What;
    end;
  end;

  function Refs(const Model, Field, Value: string): Integer;
  begin
    Result := C.Count(Model, Domain1(Field, '=', TJSONString.Create(Value)));
  end;

  { Una venta del TPV en Odoo: exactamente un pedido confirmado, sus
    entregas hechas (con Inventario) y una factura publicada. }
  function PosState(const ARef: string): string;
  var
    OIds, X, Rows: TJSONArray;
    Id, J, Live: Integer;
    InvModel: string;
  begin
    Result := '';
    OIds := C.SearchRead('sale.order', Domain1('client_order_ref', '=',
      TJSONString.Create(ARef)), ['name', 'state'], 0, '');
    try
      if OIds.Count <> 1 then Exit('orders=' + IntToStr(OIds.Count));
      Id := JInt(OIds.Objects[0], 'id');
      Result := JStr(OIds.Objects[0], 'name') + ' ' + JStr(OIds.Objects[0], 'state');
      if (JStr(OIds.Objects[0], 'state') = 'draft') or (JStr(OIds.Objects[0], 'state') = 'sent') then
        Exit('NOT_CONFIRMED ' + Result);
    finally
      OIds.Free;
    end;
    X := Sy.Ids('sale.order', Id, 'picking_ids');
    Rows := C.SearchRead('stock.picking', Domain1('id', 'in', X), ['name', 'state'], 0, '');
    try
      Live := 0;
      for J := 0 to Rows.Count - 1 do
        if JStr(Rows.Objects[J], 'state') <> 'cancel' then
        begin
          Inc(Live);
          Result := Result + ' ' + JStr(Rows.Objects[J], 'name') + '=' + JStr(Rows.Objects[J], 'state');
          if JStr(Rows.Objects[J], 'state') <> 'done' then Result := 'NOT_DONE ' + Result;
        end;
      if C.Has('sale.order', 'picking_ids') and (Live <> 1) then
        Result := 'PICKINGS=' + IntToStr(Live) + ' ' + Result;
    finally
      Rows.Free;
    end;
    if C.Major >= 13 then InvModel := 'account.move' else InvModel := 'account.invoice';
    X := Sy.Ids('sale.order', Id, 'invoice_ids');
    Rows := C.SearchRead(InvModel, Domain1('id', 'in', X), ['name', 'number', 'state'], 0, '');
    try
      Live := 0;
      for J := 0 to Rows.Count - 1 do
        if JStr(Rows.Objects[J], 'state') <> 'cancel' then
        begin
          Inc(Live);
          Result := Result + ' ' + JStr(Rows.Objects[J], 'number') +
            JStr(Rows.Objects[J], 'name') + '=' + JStr(Rows.Objects[J], 'state');
          if JStr(Rows.Objects[J], 'state') = 'draft' then Result := 'NOT_POSTED ' + Result;
        end;
      if Live <> 1 then Result := 'INVOICES=' + IntToStr(Live) + ' ' + Result;
    finally
      Rows.Free;
    end;
  end;

  function PosOk(const State: string): Boolean;
  begin
    Result := (State <> '') and (Pos('NOT_', State) = 0) and (Pos('=', Copy(State, 1, 9)) = 0) and
      (Pos('INVOICES=', State) = 0) and (Pos('PICKINGS=', State) = 0) and (Pos('orders=', State) = 0);
  end;

begin
  Fails := '';
  SetupOpenSSL;
  Cfg := TJSONObject(GetJSON(ReadText(GetEnvironmentVariable('DMS_ODOO_SELFTEST'))));
  Dir := GetTempDir(False) + 'dms_odoo_selftest' + PathDelim;
  ForceDirectories(Dir);
  DeleteFile(Dir + 'data.json');
  St := TOdooStore.Create(Dir + 'data.json');
  C := TOdooClient.Create;
  Sy := TOdooSync.Create(C, St);
  C.Url := JStr(Cfg, 'url');
  C.Login := JStr(Cfg, 'login');
  Pass := JStr(Cfg, 'password');
  Db := JStr(Cfg, 'db');
  try
    // Errores claros: contraseña mala y base de datos que no existe.
    C.Db := Db;
    C.Password := Pass + '-mal';
    try
      Sy.Connect;
      Check(False, 'bad_password');
    except
      on E: EOdoo do Check(E.Kind = oeLogin, 'bad_password (' + E.Message + ')');
    end;
    C.Db := 'dms_no_existe';
    C.Password := Pass;
    try
      Sy.Connect;
      Check(False, 'bad_database');
    except
      on E: EOdoo do
        Check(E.Kind in [oeDatabase, oeLogin], 'bad_database (' + E.Message + ')');
    end;
    // Base de datos vacía: se detecta si el servidor la dice.
    C.Db := '';
    try
      Sy.Connect;
      WriteLn('info detect_db -> ', C.Db);
    except
      on E: EOdoo do WriteLn('info detect_db: ', E.Message);
    end;
    C.Db := Db;
    Sy.Connect;
    Check(C.Uid > 0, 'login Odoo ' + C.Version + ' major ' + IntToStr(C.Major));
    Sy.Download;
    Check(St.List('partners').Count > 0, 'download partners=' +
      IntToStr(St.List('partners').Count));
    Check(St.List('products').Count > 0, 'download products=' +
      IntToStr(St.List('products').Count));
    Check(not Sy.SaleMissing, 'download orders=' + IntToStr(St.List('orders').Count) +
      ' currency=' + CurSymbol);
    // Sin conexión: un cliente nuevo y su presupuesto, a la bandeja de salida.
    P := St.AddPartner('DMS Prueba ' + FormatDateTime('hhnnss', Now),
      'prueba@example.com', '+34 600 000 000', 'Calle Mayor 1', 'Madrid', '');
    Ref := JStr(P, 'ref');
    Prods := St.List('products');
    L := TJSONArray.Create;
    for I := 0 to Min(1, Prods.Count - 1) do
      L.Add(TJSONObject.Create(['product_id', JInt(Prods.Objects[I], 'id'),
        'name', JStr(Prods.Objects[I], 'name'), 'qty', 2 - I,
        'price', JNum(Prods.Objects[I], 'price'),
        'uom', JInt(Prods.Objects[I], 'uom')]));
    O := St.AddOrder(P, L);
    ORef := JStr(O, 'ref');
    Check(St.Pending = 2, 'offline_queued');
    // Se cierra y se vuelve a abrir: la bandeja de salida sigue ahí.
    Sy.Free;
    St.Free;
    St := TOdooStore.Create(Dir + 'data.json');
    Sy := TOdooSync.Create(C, St);
    Prods := St.List('products'); // la lista de antes ya no existe
    // Para el punto de venta, productos que se entregan (no servicios: en
    // los datos de ejemplo de Odoo 8 el primero es «Advance», un servicio, y
    // un pedido solo de servicios no tiene entrega).
    Goods := TJSONArray.Create;
    Rows := C.SearchRead('product.product', Domain1('type', 'in',
      TJSONArray.Create(['product', 'consu'])), ['name'], 0, '');
    for I := 0 to Prods.Count - 1 do
      for J := 0 to Rows.Count - 1 do
        if JInt(Rows.Objects[J], 'id') = JInt(Prods.Objects[I], 'id') then
          Goods.Add(Prods.Objects[I].Clone);
    Rows.Free;
    if Goods.Count = 0 then
      for I := 0 to Prods.Count - 1 do Goods.Add(Prods.Objects[I].Clone);
    Check(St.Pending = 2, 'offline_saved');
    Check((Sy.Push = 2) and (St.Pending = 0), 'sync_push');
    Check((Refs('res.partner', 'ref', Ref) = 1) and
      (Refs('sale.order', 'client_order_ref', ORef) = 1), 'sync_created');
    P := St.Find('partners', 0, Ref);
    O := St.Find('orders', 0, ORef);
    Pid := JInt(P, 'id');
    Oid := JInt(O, 'id');
    WriteLn('info order ', JStr(O, 'name'), ' state=', JStr(O, 'state'),
      ' amount=', JNum(O, 'amount'):0:2, ' partner=', Pid);
    // Como si la respuesta se hubiera perdido: se reenvía y no se duplica.
    P.Integers['id'] := 0;
    P.Booleans['pending'] := True;
    O.Integers['id'] := 0;
    O.Integers['partner_id'] := 0;
    O.Booleans['pending'] := True;
    St.Queue('partner_create', Ref, 0);
    St.Queue('order_create', ORef, 0);
    Sy.Push;
    Check((Refs('res.partner', 'ref', Ref) = 1) and
      (Refs('sale.order', 'client_order_ref', ORef) = 1) and (St.Pending = 0) and
      (JInt(P, 'id') = Pid) and (JInt(O, 'id') = Oid), 'no_duplicates');
    // Un cambio del cliente hecho sin conexión.
    St.EditPartner(P, JStr(P, 'name') + ' (editado)', 'otro@example.com', '',
      'Calle Mayor 2', 'Sevilla', '');
    Check(St.Pending = 1, 'edit_queued');
    Sy.Push;
    Rows := C.SearchRead('res.partner', Domain1('id', '=',
      TJSONIntegerNumber.Create(Pid)), ['name', 'city', 'email'], 1, '');
    Check((Rows.Count = 1) and (JStr(Rows.Objects[0], 'city') = 'Sevilla') and
      (JStr(Rows.Objects[0], 'email') = 'otro@example.com'), 'edit_synced');
    Rows.Free;
    // BIM 2.0 (si está): una obra y su presupuesto por conceptos, hechos
    // sin conexión; al sincronizar, en Odoo con los mismos importes; sin
    // duplicados al reenviar, y un envío cortado a medias se completa.
    if C.Exists('bim.budget') then
    try
      BP := St.AddBimProject('DMS Obra ' + FormatDateTime('hhnnss', Now), nil);
      BB := St.AddBimBudget(BP, 'DMS Presupuesto');
      K1 := St.AddConcept(BB, '', 'chapter', '01', 'Movimiento de tierras', 1, 0, '', BErr);
      K2 := St.AddConcept(BB, JStr(K1, 'ref'), 'departure', '01.01', 'Excavación', 120, 0, 'm3', BErr);
      St.AddConcept(BB, JStr(K2, 'ref'), 'labor', 'MO001', 'Peón', 0.5, 18, 'h', BErr);
      St.AddConcept(BB, JStr(K2, 'ref'), 'equip', 'EQ001', 'Retroexcavadora', 0.1, 45, 'h', BErr);
      // Una partida sin recursos, con su precio.
      St.AddConcept(BB, JStr(K1, 'ref'), 'departure', '01.02', 'Relleno', 10, 7.5, 'm3', BErr);
      Check(St.AddConcept(BB, '', 'labor', 'MO002', 'Sin partida', 1, 1, '', BErr) = nil,
        'bim_rules (' + BErr + ')');
      // 120 × (0,5 × 18 + 0,1 × 45) + 10 × 7,5 = 1620 + 75
      Check(Abs(JNum(BB, 'amount') - 1695) < 0.01, 'bim_local_total ' + FloatToStr(JNum(BB, 'amount')));
      St.SendBimBudget(BB);
      Check(St.Pending = 2, 'bim_queued');
      Sy.Push;
      Bid := JInt(BB, 'id');
      BPid := JInt(BP, 'id');
      BRef := JStr(BB, 'ref');
      BPRef := JStr(BP, 'ref');
      WriteLn('info bim ', JStr(BP, 'code'), ' ', JStr(BB, 'code'), ' total=',
        FloatToStr(JNum(BB, 'amount')));
      if St.Pending > 0 then WriteLn('info bim outbox ', St.List('outbox').AsJSON);
      Check((BPid > 0) and (Bid > 0) and (St.Pending = 0) and
        (C.Count('bim.concepts', Domain1('budget_id', '=', TJSONIntegerNumber.Create(Bid))) = 5) and
        (Abs(JNum(BB, 'amount') - 1695) < 0.01), 'bim_synced');
      // Como si la respuesta se hubiera perdido: se reenvía todo.
      BP.Integers['id'] := 0;
      BB.Integers['id'] := 0;
      BB.Integers['project_id'] := 0;
      St.Queue('bim_project', BPRef, 0);
      St.Queue('bim_budget', BRef, 0);
      Sy.Push;
      Check((JInt(BP, 'id') = BPid) and (JInt(BB, 'id') = Bid) and (St.Pending = 0) and
        (C.Count('bim.project', Domain1('notes', 'ilike', TJSONString.Create(BPRef))) = 1) and
        (C.Count('bim.budget', Domain1('origin', '=', TJSONString.Create(BRef))) = 1) and
        (C.Count('bim.concepts', Domain1('budget_id', '=', TJSONIntegerNumber.Create(Bid))) = 5),
        'bim_no_duplicates');
      // Cortado a medias: la cabecera y el capítulo ya llegaron a Odoo.
      BB2 := St.AddBimBudget(BP, 'DMS Presupuesto 2');
      K1 := St.AddConcept(BB2, '', 'chapter', '01', 'Cimentación', 1, 0, '', BErr);
      K2 := St.AddConcept(BB2, JStr(K1, 'ref'), 'departure', '01.01', 'Zapata', 4, 0, 'm3', BErr);
      St.AddConcept(BB2, JStr(K2, 'ref'), 'material', 'MT001', 'Hormigón', 1.05, 90, 'm3', BErr);
      Args := TJSONArray.Create;
      Args.Add(TJSONObject.Create(['name', 'DMS Presupuesto 2', 'project_id', BPid,
        'origin', JStr(BB2, 'ref'), 'currency_id', JInt(St.Settings, 'currency_id')]));
      BR := C.Kw('bim.budget', 'create', Args);
      if BR is TJSONArray then Bid2 := TJSONArray(BR).Items[0].AsInteger else Bid2 := BR.AsInteger;
      BR.Free;
      Args := TJSONArray.Create;
      Args.Add(TJSONObject.Create(['budget_id', Bid2, 'code', '01', 'name', 'Cimentación',
        'type', 'chapter', 'id_import', JStr(K1, 'ref')]));
      C.Kw('bim.concepts', 'create', Args).Free;
      St.SendBimBudget(BB2);
      Sy.Push;
      WriteLn('info bim resumed ', JStr(BB2, 'code'), ' total=', FloatToStr(JNum(BB2, 'amount')));
      // 4 × 1,05 × 90 = 378
      Check((JInt(BB2, 'id') = Bid2) and (St.Pending = 0) and
        (C.Count('bim.concepts', Domain1('budget_id', '=', TJSONIntegerNumber.Create(Bid2))) = 3) and
        (C.Count('bim.concepts', Domain1('id_import', '=', TJSONString.Create(JStr(K1, 'ref')))) = 1) and
        (Abs(JNum(BB2, 'amount') - 378) < 0.01), 'bim_resumed');
      // Al descargar, las obras y los presupuestos de Odoo (y el árbol hecho aquí).
      Sy.Download;
      BB := St.Find('bim_budgets', 0, BRef);
      Check((BB <> nil) and (JInt(BB, 'id') = Bid) and (BB.Find('concepts') is TJSONArray) and
        (St.Find('bim_projects', BPid, '') <> nil), 'bim_download');
      BB := St.Find('bim_budgets', Bid2, '');
      if BB <> nil then
      begin
        BB.Delete('concepts');
        Sy.LoadBimConcepts(BB);
        Check(BB.Arrays['concepts'].Count = 3, 'bim_load_tree');
      end
      else Check(False, 'bim_load_tree');
      // Limpieza: los conceptos de primer nivel (se llevan a sus hijos), los
      // presupuestos y la obra (BIM no deja borrar obras: se archiva).
      try
        for BI := 0 to 1 do
        begin
          if BI = 0 then BX := Bid else BX := Bid2;
          Rows := C.SearchRead('bim.concepts', Domain1('budget_id', '=',
            TJSONIntegerNumber.Create(BX)), ['parent_id'], 0, '');
          L := TJSONArray.Create;
          for I := 0 to Rows.Count - 1 do
            if not (Rows.Objects[I].Find('parent_id') is TJSONArray) then
              L.Add(JInt(Rows.Objects[I], 'id'));
          Rows.Free;
          Args := TJSONArray.Create;
          Args.Add(L);
          C.Kw('bim.concepts', 'unlink', Args).Free;
          Args := TJSONArray.Create;
          Args.Add(TJSONArray.Create([BX]));
          C.Kw('bim.budget', 'unlink', Args).Free;
        end;
        Args := TJSONArray.Create;
        Args.Add(TJSONArray.Create([BPid]));
        Args.Add(TJSONObject.Create(['active', False]));
        C.Kw('bim.project', 'write', Args).Free;
        WriteLn('info bim cleanup ok');
      except
        on E: Exception do WriteLn('info bim cleanup: ', E.Message);
      end;
    except
      on E: Exception do Check(False, 'bim exception ' + E.ClassName + ': ' + E.Message);
    end
    else WriteLn('info bim: no está BIM 2.0 en esta base de datos');
    // Punto de venta, sin conexión: el cliente de mostrador y dos líneas
    // (una con descuento). Al sincronizar: pedido confirmado, entrega
    // validada y factura publicada.
    L := TJSONArray.Create;
    for I := 0 to Min(1, Goods.Count - 1) do
      L.Add(TJSONObject.Create(['product_id', JInt(Goods.Objects[I], 'id'),
        'name', JStr(Goods.Objects[I], 'name'), 'qty', 2 - I,
        'price', JNum(Goods.Objects[I], 'price'), 'discount', 10 * I,
        'uom', JInt(Goods.Objects[I], 'uom')]));
    O := St.AddPos(St.CounterPartner, L, 'card');
    Sale1 := JStr(O, 'ref');
    Check(St.Pending >= 1, 'pos_offline_queued');
    Sy.Push;
    O := St.Find('orders', 0, Sale1);
    Before := PosState(Sale1);
    WriteLn('info pos ', Before, ' step=', JStr(O, 'step'), ' error=', JStr(O, 'error'));
    Check(PosOk(Before) and (JStr(O, 'step') = 'invoiced') and (St.Pending = 0), 'pos_synced');
    WriteLn('info receipt: ', StringReplace(Receipt(O), LineEnding, ' | ', [rfReplaceAll]));
    // Como si la respuesta se hubiera perdido: se reenvía entera.
    O.Integers['id'] := 0;
    O.Strings['step'] := 'pending';
    O.Booleans['pending'] := True;
    St.Queue('pos_sale', Sale1, 0);
    Sy.Push;
    Check((PosState(Sale1) = Before) and (St.Pending = 0), 'pos_no_duplicates');
    // Se corta a medias: el pedido ya está confirmado en Odoo, pero sin
    // entrega ni factura. Al sincronizar se sigue desde ahí.
    L := TJSONArray.Create;
    L.Add(TJSONObject.Create(['product_id', JInt(Goods.Objects[0], 'id'),
      'name', JStr(Goods.Objects[0], 'name'), 'qty', 3,
      'price', JNum(Goods.Objects[0], 'price'), 'discount', 0,
      'uom', JInt(Goods.Objects[0], 'uom')]));
    O := St.AddPos(St.CounterPartner, L, 'cash');
    Sale2 := JStr(O, 'ref');
    Sy.Confirm(Sy.EnsureOrder(O));
    Check(Pos('NOT_DONE', PosState(Sale2)) + Pos('INVOICES=0', PosState(Sale2)) > 0,
      'pos_half_done ' + PosState(Sale2));
    Sy.Push;
    Before := PosState(Sale2);
    WriteLn('info pos resumed ', Before);
    Check(PosOk(Before) and (St.Pending = 0), 'pos_resumed');
    Sy.Push;
    Check(PosState(Sale2) = Before, 'pos_resume_idempotent');
    // Una segunda descarga conserva lo enviado.
    Sy.Download;
    Check(St.Find('orders', Oid, '') <> nil, 'download_after_sync');
    O := St.Find('orders', 0, Sale1);
    Check((O <> nil) and JBool(O, 'pos') and (JStr(O, 'invoice') <> ''),
      'pos_kept_after_download');
    // Limpieza: se borra lo creado.
    Args := TJSONArray.Create;
    Args.Add(TJSONArray.Create([Oid]));
    C.Kw('sale.order', 'unlink', Args).Free;
    Args := TJSONArray.Create;
    Args.Add(TJSONArray.Create([Pid]));
    C.Kw('res.partner', 'unlink', Args).Free;
    Check((Refs('res.partner', 'ref', Ref) = 0) and
      (Refs('sale.order', 'client_order_ref', ORef) = 0), 'cleanup');
  except
    on E: Exception do Check(False, 'exception ' + E.ClassName + ': ' + E.Message);
  end;
  Sy.Free;
  St.Free;
  C.Free;
  Cfg.Free;
  DeleteFile(Dir + 'data.json');
  if Fails = '' then WriteLn('RESULT OK') else WriteLn('RESULT FAIL', Fails);
  if Fails = '' then Halt(0) else Halt(1);
end;

''';

/// El código con la prueba: si DMS_ODOO_SELFTEST dice dónde están los datos
/// del servidor, la hace sin abrir la ventana; si no, abre la aplicación con
/// sus datos en [store] y, con DMS_ODOO_SMOKE, se cierra al terminar de abrir.
String testCode(String code, String store) => code
    .replaceFirst(
      "DataDir + 'odoo-offline.json'",
      TkPascal.str(store),
    )
    .replaceFirst('destructor TForm1.Destroy;', '${_selfTest}destructor TForm1.Destroy;')
    .replaceFirst(
      'procedure TForm1.form_create;\nbegin\n',
      "procedure TForm1.form_create;\nbegin\n  if GetEnvironmentVariable('DMS_ODOO_SELFTEST') <> '' then DmsSelfTest;\n",
    )
    .replaceFirst(
      '  if Configured and SyncAuto.Checked',
      "  if GetEnvironmentVariable('DMS_ODOO_SMOKE') <> '' then\n"
          '  begin\n'
          "    WriteLn('smoke pages=', Pages.PageCount, ' tabs=', Pages.ShowTabs,\n"
          "      ' kpi=', KpiSalesVal.Caption, ' nav=', NavPanel.Caption);\n"
          '    Application.Terminate;\n'
          '  end;\n'
          '  if Configured and SyncAuto.Checked',
    );

/// Compila con lazbuild en [dir]; devuelve el ejecutable (o falla).
Future<String> build(TkExample e, String code, Directory dir) async {
  final files = TkPascal.files(
    e.design,
    code,
    options: await TkPascalTools.options(),
  );
  for (final f in files.entries) {
    File(p.join(dir.path, f.key)).writeAsStringSync(f.value);
  }
  final r = await Process.run(TkPascalTools.lazbuild()!, [
    ...TkPascalTools.args(),
    'app.lpi',
  ], workingDirectory: dir.path);
  final exe = p.join(dir.path, Platform.isWindows ? 'app.exe' : 'app');
  expect(
    r.exitCode == 0 && File(exe).existsSync(),
    isTrue,
    reason: TkPascalTools.messages('${r.stdout}${r.stderr}', dir.path).join('\n'),
  );
  return exe;
}

void main() {
  final e = tkUtilPascalOdoo(id);

  test('diseño: Pascal, sin problemas y con lo que usa el código', () {
    final d = e.design;
    expect(e.seed, 'pascal_odoo');
    expect(d.isPascal, isTrue);
    expect(d.problems(), isEmpty);
    expect(d.width, lessThanOrEqualTo(1100));
    expect(d.height, lessThanOrEqualTo(720));
    // Solo componentes que tiene Pascal; los gráficos se dibujan en código.
    for (final w in d.widgets) {
      expect(tkPascalKinds, contains(w.kind), reason: w.name);
    }
    final names = {for (final w in d.widgets) w.name};
    for (final n in [
      'Side',
      'NavPanel',
      'NavSettings',
      'Pages',
      'KpiSalesVal',
      'ChartMonth',
      'ChartState',
      'ChartTop',
      'CustList',
      'ProdList',
      'SaleList',
      'QuoteCust',
      'Outbox',
      'SyncLog',
      'CfgUrl',
      'CfgPass',
      'NavPos',
      'PosGrid',
      'PosLines',
      'PosPay',
      'Tick',
      'NavBim',
      'BimProject',
      'BimBudSel',
      'BimTree',
      'BimRows',
      'BimType',
      'BimSend',
    ]) {
      expect(names, contains(n));
    }
    // Cada método de un evento está en el código, con override.
    for (final w in d.widgets) {
      for (final m in w.events.values) {
        expect(e.code, contains('procedure $m; override;'), reason: m);
        expect(e.code, contains('procedure TForm1.$m;'), reason: m);
      }
    }
    // Las páginas caben en la ventana.
    for (final w in d.widgets.where((w) => w.parent == null)) {
      expect(w.x + w.width, lessThanOrEqualTo(d.width), reason: w.name);
      expect(w.y + w.height, lessThanOrEqualTo(d.height), reason: w.name);
    }
  });

  test('código: JSON-RPC de Odoo, sin conexión y sin duplicados', () {
    final files = TkPascal.files(e.design, e.code);
    expect(
      files.keys,
      containsAll(['dms.pas', 'design.pas', 'Form1.pas', 'app.lpr', 'app.lpi']),
    );
    final unit = files['Form1.pas']!;
    for (final u in [
      'fphttpclient',
      'opensslsockets',
      'openssl',
      'fpjson',
      'jsonparser',
    ]) {
      expect(unit, contains(u));
    }
    for (final s in [
      '/web/session/authenticate',
      '/web/dataset/call_kw/',
      '/web/webclient/version_info',
      '/web/database/list',
      '/web/database/get_list',
      'session_id=',
      'customer_rank',
      "'customer'",
      'client_order_ref',
      'product_uom_id',
      'qty_available',
      'onchange_partner_id',
      'active_test',
      'TPaintBox',
      'lbOwnerDrawFixed',
      'ShowTabs := False',
      // Punto de venta: confirmar, entregar y facturar según la versión.
      'action_button_confirm',
      'action_confirm',
      'do_new_transfer',
      'do_transfer',
      'button_validate',
      'force_assign',
      "'picked'",
      'quantity_done',
      'stock.immediate.transfer',
      'confirm.stock.sms',
      'sale.advance.payment.inv',
      'create_invoices',
      'action_post',
      'action_invoice_open',
      'signal_workflow',
      'DMS-POS',
      // BIM 2.0: obra, presupuesto y conceptos, sin duplicados.
      'bim.project',
      'bim.budget',
      'bim.concepts',
      'id_import',
      'update_amount',
      "'bim_budget'",
      // OpenSSL: junto al ejecutable, en Contents/Frameworks y la del sistema.
      '../Frameworks',
      'InitSSLInterface',
    ]) {
      expect(unit, contains(s), reason: s);
    }
    // Ningún texto queda sin constante (no hay comillas triples rotas).
    expect(unit, isNot(contains("'''")));
    // Por RPC no se puede llamar a métodos que empiezan por «_».
    expect(
      RegExp(r"Kw\('[\w.]+', '_").hasMatch(unit),
      isFalse,
    );
    expect(unit, contains("SApp = 'Odoo sin conexión';"));
    // En inglés, los textos se traducen y el código sigue igual.
    final en = tkUtilPascalOdoo((s) => s == 'Panel' ? 'Dashboard' : s);
    expect(en.code, contains("'Dashboard|Clientes"));
  });

  test(
    'de verdad: compila con Lazarus y abre',
    () async {
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final tmp = await Directory.systemTemp.createTemp('dms_odoo_');
      addTearDown(() => tmp.delete(recursive: true));
      final store = p.join(tmp.path, 'store.json');
      final exe = await build(e, testCode(e.code, store), tmp);
      final r = await Process.run(
        exe,
        const [],
        environment: {'DMS_ODOO_SMOKE': '1'},
      ).timeout(const Duration(minutes: 1));
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect('${r.stdout}', contains('smoke pages=8 tabs=FALSE'));
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  // Contra servidores de Odoo reales: solo en local, con DMS_ODOO_TEST=1 y
  // DMS_ODOO_CREDS = un JSON {"17": {"url", "db", "login", "password"}, …}
  // (DMS_ODOO_VERSIONS=9,17 para probar solo esas). Nunca en CI.
  test(
    'de verdad: Odoo por versión (con DMS_ODOO_TEST=1)',
    () async {
      final creds = Platform.environment['DMS_ODOO_CREDS'] ?? '';
      if (Platform.environment['DMS_ODOO_TEST'] != '1' ||
          creds.isEmpty ||
          !File(creds).existsSync()) {
        return markTestSkipped('Sin DMS_ODOO_TEST=1 y DMS_ODOO_CREDS.');
      }
      if (TkPascalTools.lazbuild() == null) {
        return markTestSkipped('Sin Lazarus.');
      }
      final all = (jsonDecode(File(creds).readAsStringSync()) as Map)
          .cast<String, Object?>();
      final only = (Platform.environment['DMS_ODOO_VERSIONS'] ?? '')
          .split(',')
          .where((v) => v.trim().isNotEmpty)
          .toSet();
      final tmp = await Directory.systemTemp.createTemp('dms_odoo_net_');
      addTearDown(() => tmp.delete(recursive: true));
      final exe = await build(
        e,
        testCode(e.code, p.join(tmp.path, 'store.json')),
        tmp,
      );
      final results = <String, bool>{};
      final versions = all.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      for (final v in versions) {
        if (only.isNotEmpty && !only.contains(v)) continue;
        final cfg = File(p.join(tmp.path, 'cfg_$v.json'))
          ..writeAsStringSync(jsonEncode(all[v]));
        final r = await Process.run(
          exe,
          const [],
          environment: {'DMS_ODOO_SELFTEST': cfg.path},
        ).timeout(const Duration(minutes: 5));
        cfg.deleteSync();
        final out = '${r.stdout}${r.stderr}';
        // ignore: avoid_print
        print('--- Odoo $v\n$out');
        results[v] = r.exitCode == 0 && out.contains('RESULT OK');
      }
      // ignore: avoid_print
      print('Resultados: $results');
      expect(results.values, everyElement(isTrue), reason: '$results');
    },
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
