program main;
procedure QuickSort(var a: array of Integer; lo, hi: Integer);
var i, j, tmp: Integer;
begin
  i := lo;
  for j := lo to hi - 1 do
    if a[j] < a[hi] then  // a[hi] is the pivot
    begin
      tmp := a[i]; a[i] := a[j]; a[j] := tmp;
      Inc(i);
    end;
  tmp := a[i]; a[i] := a[hi]; a[hi] := tmp;    // the pivot to its final place
  if lo < i - 1 then QuickSort(a, lo, i - 1);  // smaller values, on the left
  if i + 1 < hi then QuickSort(a, i + 1, hi);  // bigger ones, on the right
end;
function Find(const a: array of Integer; target, lo, hi: Integer): Integer;
var mid: Integer;
begin
  if lo > hi then Exit(-1);  // nothing left to look at
  mid := (lo + hi) div 2;
  if a[mid] = target then Result := mid
  else if a[mid] < target then Result := Find(a, target, mid + 1, hi)
  else Result := Find(a, target, lo, mid - 1);
end;

var
  codes: array of Integer = (4021, 1187, 9350, 2764, 5512, 3308, 7045);
  code: Integer;
begin
  QuickSort(codes, 0, High(codes));
  for code in codes do Write(code, ' ');
  WriteLn(LineEnding, '5512 is at index ', Find(codes, 5512, 0, High(codes)));
  WriteLn('6000 is at index ', Find(codes, 6000, 0, High(codes)));
end.
