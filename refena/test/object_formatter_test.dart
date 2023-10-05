import 'package:refena/src/util/object_formatter.dart';
import 'package:test/test.dart';

void main() {
  test('Should format null', () {
    final s = formatValue(null);
    expect(s, 'null');
  });

  test('Should format map', () {
    final s = formatValue({
      'a': 1,
      'b': {'c': 2}
    });
    expect(s, '''
{
  "a": 1,
  "b": {
    "c": 2
  }
}''');
  });

  test('Should format json string', () {
    final s = formatValue('{"a": 1, "b": {"c": 2}}');
    expect(s, '''
{
  "a": 1,
  "b": {
    "c": 2
  }
}''');
  });

  test('Should format class', () {
    final s = formatValue('Hell_oo(abc: 332, cd: <ee>)');
    expect(s, '''
Hell_oo(
  abc: 332,
  cd: <ee>
)''');
  });

  test('Should format class with generics', () {
    final s = formatValue('Hell_oo<int, b>(abc: 332, cd: <ee>)');
    expect(s, '''
Hell_oo<int, b>(
  abc: 332,
  cd: <ee>
)''');
  });

  test('Should format class toString nested', () {
    final s = formatValue('Hell_oo(abc: 332, cd: Ab(a: 3))');
    expect(s, '''
Hell_oo(
  abc: 332,
  cd: Ab(
    a: 3
  )
)''');
  });

  test('Should not support commas', () {
    final s = formatValue('Hell_oo(abc: 332, cd: <ee>, f: [1, 2])');
    expect(s, 'Hell_oo(abc: 332, cd: <ee>, f: [1, 2])');
  });

  test('Should not line breaks', () {
    final s = formatValue('Hell_oo(abc: 3\n32)');
    expect(s, 'Hell_oo(abc: 3\n32)');
  });
}
