// Las ventanas visibles del proceso [pid], de la más antigua a la más nueva:
// una por línea, su número (para screencapture -l). Lo usa tk_run.py.
import CoreGraphics
import Foundation

let pid = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
let ids = list
  .filter { ($0[kCGWindowOwnerPID as String] as? Int) == pid }
  .filter { (($0[kCGWindowBounds as String] as? [String: Any])?["Height"] as? Double ?? 0) > 40 }
  .compactMap { $0[kCGWindowNumber as String] as? Int }
  .sorted()
for id in ids { print(id) }
