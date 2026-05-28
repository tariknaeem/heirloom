import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/features/person/person_form.dart';
import 'package:heirloom/models.dart';

void main() {
  test('validate requires a name', () {
    expect(PersonDraft(displayName: '').validate(), isNotNull);
    expect(PersonDraft(displayName: 'Jane').validate(), isNull);
  });
  test('toPerson roundtrips fields and generates an id', () {
    final d = PersonDraft(displayName: 'Jane', given: 'Jane', family: 'Doe', birthDate: '1990-01-01', isLiving: true);
    final p = d.toPerson();
    expect(p.id.isNotEmpty, true);
    expect(p.displayName, 'Jane'); expect(p.family, 'Doe'); expect(p.birthDate, '1990-01-01');
  });
  test('PersonDraft.from(existing) preserves id on save', () {
    final orig = Person(id: 'fixed', displayName: 'X');
    final d = PersonDraft.from(orig)..displayName = 'Y';
    expect(d.toPerson(id: orig.id).id, 'fixed');
    expect(d.toPerson(id: orig.id).displayName, 'Y');
  });
}
