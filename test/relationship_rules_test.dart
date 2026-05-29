import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/features/person/relationship_rules.dart';
import 'package:heirloom/models.dart';

Relationship _pc(String parent, String child) => Relationship(
      id: '$parent-$child',
      type: RelType.parentChild,
      personA: parent,
      personB: child,
    );

Relationship _sp(String a, String b) =>
    Relationship(id: '$a~$b', type: RelType.spouse, personA: a, personB: b);

void main() {
  group('canAddParentChild', () {
    test('allows a normal new parent link', () {
      expect(canAddParentChild('dad', 'me', const []).ok, isTrue);
    });

    test('rejects self-parenting', () {
      final c = canAddParentChild('me', 'me', const []);
      expect(c.ok, isFalse);
      expect(c.reason, contains('own parent'));
    });

    test('rejects an exact duplicate link', () {
      final existing = [_pc('dad', 'me')];
      expect(canAddParentChild('dad', 'me', existing).ok, isFalse);
    });

    test('rejects a direct cycle (child becomes parent of their parent)', () {
      // dad is parent of me. Trying to make me the parent of dad → loop.
      final existing = [_pc('dad', 'me')];
      final c = canAddParentChild('me', 'dad', existing);
      expect(c.ok, isFalse);
      expect(c.reason, isNotNull);
    });

    test('rejects a deep cycle through grandparents', () {
      // grandpa -> dad -> me. Making grandpa a child of me would loop.
      final existing = [_pc('grandpa', 'dad'), _pc('dad', 'me')];
      final c = canAddParentChild('me', 'grandpa', existing);
      expect(c.ok, isFalse);
      expect(c.reason, contains('loop'));
    });

    test('allows linking an unrelated second parent', () {
      final existing = [_pc('dad', 'me')];
      expect(canAddParentChild('mom', 'me', existing).ok, isTrue);
    });
  });

  group('canAddSpouse', () {
    test('allows a new spouse link', () {
      expect(canAddSpouse('a', 'b', const []).ok, isTrue);
    });

    test('rejects self-marriage', () {
      expect(canAddSpouse('a', 'a', const []).ok, isFalse);
    });

    test('rejects an existing spouse link regardless of direction', () {
      final existing = [_sp('a', 'b')];
      expect(canAddSpouse('a', 'b', existing).ok, isFalse);
      expect(canAddSpouse('b', 'a', existing).ok, isFalse);
    });
  });

  group('ancestorsOf', () {
    test('collects multi-generation ancestors', () {
      final rels = [_pc('grandpa', 'dad'), _pc('dad', 'me')];
      expect(ancestorsOf('me', rels), {'dad', 'grandpa'});
    });

    test('is cycle-safe and terminates', () {
      // Corrupt data: a -> b -> a.
      final rels = [_pc('a', 'b'), _pc('b', 'a')];
      final anc = ancestorsOf('a', rels);
      expect(anc, containsAll({'a', 'b'}));
    });
  });
}
