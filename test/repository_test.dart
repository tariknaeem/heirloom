import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/models.dart';
import 'package:heirloom/repository.dart';

void main() {
  late InMemoryFamilyRepository repo;
  setUp(() => repo = InMemoryFamilyRepository());

  test('parents, children, siblings, spouses', () async {
    final me = Person(id: 'me', displayName: 'Me');
    final mom = Person(id: 'mom', displayName: 'Mom');
    final dad = Person(id: 'dad', displayName: 'Dad');
    final sib = Person(id: 'sib', displayName: 'Sib');
    for (final p in [me, mom, dad, sib]) {
      await repo.upsertPerson(p);
    }
    await repo.addRelationship(
        Relationship(id: 'r1', type: RelType.parentChild, personA: 'mom', personB: 'me'));
    await repo.addRelationship(
        Relationship(id: 'r2', type: RelType.parentChild, personA: 'dad', personB: 'me'));
    await repo.addRelationship(
        Relationship(id: 'r3', type: RelType.parentChild, personA: 'mom', personB: 'sib'));
    await repo.addRelationship(
        Relationship(id: 'r4', type: RelType.spouse, personA: 'mom', personB: 'dad'));

    expect((await repo.parentsOf('me')).map((p) => p.id).toSet(), {'mom', 'dad'});
    expect((await repo.childrenOf('mom')).map((p) => p.id).toSet(), {'me', 'sib'});
    expect((await repo.siblingsOf('me')).map((p) => p.id).toSet(), {'sib'});
    expect((await repo.spousesOf('mom')).map((p) => p.id).toSet(), {'dad'});
  });

  test('deletePerson removes their relationships', () async {
    await repo.upsertPerson(Person(id: 'a', displayName: 'A'));
    await repo.upsertPerson(Person(id: 'b', displayName: 'B'));
    await repo.addRelationship(
        Relationship(id: 'r', type: RelType.parentChild, personA: 'a', personB: 'b'));
    await repo.deletePerson('a');
    expect(await repo.allRelationships(), isEmpty);
    expect(await repo.getPerson('a'), isNull);
  });
}
