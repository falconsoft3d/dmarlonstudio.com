void main() {
  String day = 'Sat'; // switch runs the case that matches
  switch (day) {
    case 'Sat' || 'Sun':
      print('$day: weekend, the shop opens at 10.');
    default:
      print('$day: open from 9 to 8.');
  }

  // switch expression: gives back a value. _ catches the rest.
  int month = 4;
  String season = switch (month) {
    12 || 1 || 2 => 'winter',
    3 || 4 || 5 => 'spring',
    6 || 7 || 8 => 'summer',
    _ => 'autumn',
  };
  print('Month $month is in $season.');

  // Patterns can also compare: >= 90, >= 70...
  int score = 84;
  String grade = switch (score) { >= 90 => 'A', >= 70 => 'B', >= 50 => 'C', _ => 'F' };
  print('Score $score: grade $grade');

  // && joins two patterns; "when" adds an extra condition.
  int speed = 65;
  bool school = true;
  String note = switch (speed) {
    >= 0 && <= 50 => 'within the limit',
    _ when school => 'too fast near a school',
    _ => 'slow down',
  };
  print('$speed km/h: $note');
}
