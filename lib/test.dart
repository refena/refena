void main() async {
  print('Start');
  final number = await _number;
  print('Number: $number');
  final number2 = await _number;
  print('Number2: $number2');
}

Future<int> _number = getNumber();

Future<int> getNumber() async {
  await Future.delayed(const Duration(seconds: 3));
  return 1;
}
