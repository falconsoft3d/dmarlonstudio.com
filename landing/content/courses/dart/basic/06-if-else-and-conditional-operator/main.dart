void main() {
  int temperature = 31;

  // if runs its block only when the condition is true.
  if (temperature > 30) {
    print('It is $temperature degrees: drink water.');
  }

  // else if and else choose one path out of several.
  int score = 72;
  String grade;
  if (score >= 90) {
    grade = 'A';
  } else if (score >= 70) {
    grade = 'B';
  } else if (score >= 50) {
    grade = 'C';
  } else {
    grade = 'F';
  }
  print('Score $score: grade $grade');

  // && (and), || (or) and ! (not) combine conditions.
  int age = 16;
  bool withParent = true;
  bool isWeekend = false;
  if (age >= 18 || withParent) print('You can see the film.');
  if (!isWeekend && temperature > 25) print('A hot working day.');
  print('Is it a B? ${grade == 'B'}');

  // condition ? valueIfTrue : valueIfFalse
  String ticket = age < 18 ? 'junior' : 'adult';
  print('Ticket: $ticket, result: ${score >= 50 ? 'pass' : 'fail'}');
}
