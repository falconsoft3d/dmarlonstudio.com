// sealed: every subtype is declared in this file, so the compiler
// knows the complete list and can check that a switch covers it.
sealed class LoadState {}

class Loading extends LoadState {}
class Loaded extends LoadState {
  final List<String> items;
  Loaded(this.items);
}
class Failed extends LoadState {
  final int code;
  final String message;
  Failed(this.code, this.message);
}

// Exhaustive switch: no default needed; forget a case and it won't compile.
String render(LoadState state) => switch (state) {
      Loading() => 'Showing spinner...',
      Loaded(items: []) => 'Nothing here yet',
      Loaded(:final items) when items.length == 1 => 'One item: ${items[0]}',
      Loaded(:final items) => '${items.length} items: ${items.join(', ')}',
      Failed(code: 401) => 'Session expired, please log in',
      Failed(:final code, :final message) => 'Error $code: $message',
    };

void main() {
  final states = [Loading(), Loaded([]), Loaded(['Milk']), Loaded(['Tea', 'Rice']),
      Failed(401, 'Unauthorized'), Failed(503, 'Server busy')];
  for (final state in states) print(render(state));

  // Patterns also check and unpack a map, such as decoded JSON.
  final Object json = {'user': 'carmen', 'roles': ['admin', 'editor']};
  if (json case {'user': String name, 'roles': [String role, ...]}) print('$name is $role');
}
