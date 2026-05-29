import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/features/tree/tree_layout.dart';
import 'package:heirloom/models.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

Person _person(String id, String name) => Person(id: id, displayName: name);

Relationship _parentChild(String parentId, String childId) => Relationship(
      id: '$parentId-$childId',
      type: RelType.parentChild,
      personA: parentId,
      personB: childId,
    );

/// Small family:
///   patGrandma (gen 2) ──┐
///   patGrandpa (gen 2) ──┤
///                        dad (gen 1) ──┐
///   matGrandma (gen 2) ──┤             ├── me (gen 0)
///   matGrandpa (gen 2) ──┘             │
///                        mom (gen 1) ──┘
List<Person> _familyPeople() => [
      _person('me', 'Me'),
      _person('mom', 'Mom'),
      _person('dad', 'Dad'),
      _person('patGrandma', 'Pat. Grandma'),
      _person('patGrandpa', 'Pat. Grandpa'),
      _person('matGrandma', 'Mat. Grandma'),
      _person('matGrandpa', 'Mat. Grandpa'),
    ];

List<Relationship> _familyRels() => [
      _parentChild('mom', 'me'),
      _parentChild('dad', 'me'),
      _parentChild('patGrandma', 'dad'),
      _parentChild('patGrandpa', 'dad'),
      _parentChild('matGrandma', 'mom'),
      _parentChild('matGrandpa', 'mom'),
    ];

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('layoutPedigree', () {
    test('returns one node per ancestor including root', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      expect(result.nodes.length, 7); // me + mom + dad + 4 grandparents
    });

    test('root has generation 0', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      final meNode =
          result.nodes.firstWhere((n) => n.person.id == 'me');
      expect(meNode.generation, 0);
    });

    test('mom and dad have generation 1', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      final momNode =
          result.nodes.firstWhere((n) => n.person.id == 'mom');
      final dadNode =
          result.nodes.firstWhere((n) => n.person.id == 'dad');
      expect(momNode.generation, 1);
      expect(dadNode.generation, 1);
    });

    test('grandparents have generation 2', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      final grandParentIds = {
        'patGrandma',
        'patGrandpa',
        'matGrandma',
        'matGrandpa'
      };
      for (final n in result.nodes) {
        if (grandParentIds.contains(n.person.id)) {
          expect(n.generation, 2,
              reason: '${n.person.id} should be generation 2');
        }
      }
    });

    test('width and height are greater than zero', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });

    test('edges include [mom, me] and [dad, me]', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      final edgePairs = result.edges.map((e) => '${e[0]}->${e[1]}').toSet();
      expect(edgePairs, contains('mom->me'));
      expect(edgePairs, contains('dad->me'));
    });

    test('no two nodes in the same generation share identical (x, y)', () {
      final result = layoutPedigree('me', _familyPeople(), _familyRels());
      // Group nodes by generation
      final byGen = <int, List<TreeNode>>{};
      for (final n in result.nodes) {
        byGen.putIfAbsent(n.generation, () => []).add(n);
      }
      for (final entry in byGen.entries) {
        final nodes = entry.value;
        final coords = nodes.map((n) => '${n.x},${n.y}').toSet();
        expect(coords.length, nodes.length,
            reason:
                'Generation ${entry.key} has two nodes at the same position');
      }
    });

    test('single-person tree returns exactly 1 node, no edges, sane size', () {
      final people = [_person('solo', 'Solo Person')];
      final result = layoutPedigree('solo', people, []);
      expect(result.nodes.length, 1);
      expect(result.edges.isEmpty, isTrue);
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });
  });

  group('layoutHorizontal', () {
    test('returns one node per ancestor including root', () {
      final result =
          layoutHorizontal('me', _familyPeople(), _familyRels());
      expect(result.nodes.length, 7);
    });

    test('root has generation 0 with smallest x', () {
      final result =
          layoutHorizontal('me', _familyPeople(), _familyRels());
      final meNode =
          result.nodes.firstWhere((n) => n.person.id == 'me');
      expect(meNode.generation, 0);
      // All other nodes have gen > 0 → larger x
      for (final n in result.nodes) {
        if (n.person.id != 'me') {
          expect(n.x, greaterThan(meNode.x),
              reason: '${n.person.id} (gen ${n.generation}) should have x > root x');
        }
      }
    });

    test('increasing x by generation: gen2 node.x > gen1 node.x > gen0 node.x',
        () {
      final result =
          layoutHorizontal('me', _familyPeople(), _familyRels());
      final gen0x =
          result.nodes.where((n) => n.generation == 0).map((n) => n.x).first;
      final gen1x =
          result.nodes.where((n) => n.generation == 1).map((n) => n.x).first;
      final gen2x =
          result.nodes.where((n) => n.generation == 2).map((n) => n.x).first;
      expect(gen1x, greaterThan(gen0x));
      expect(gen2x, greaterThan(gen1x));
    });

    test('width and height are greater than zero', () {
      final result =
          layoutHorizontal('me', _familyPeople(), _familyRels());
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });

    test('edges include parent->child pairs for all relationships', () {
      final result =
          layoutHorizontal('me', _familyPeople(), _familyRels());
      final edgePairs = result.edges.map((e) => '${e[0]}->${e[1]}').toSet();
      expect(edgePairs, contains('mom->me'));
      expect(edgePairs, contains('dad->me'));
      expect(edgePairs, contains('patGrandma->dad'));
      expect(edgePairs, contains('matGrandma->mom'));
    });

    test('single-person tree returns exactly 1 node, no edges, sane size', () {
      final people = [_person('solo', 'Solo Person')];
      final result = layoutHorizontal('solo', people, []);
      expect(result.nodes.length, 1);
      expect(result.edges.isEmpty, isTrue);
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });
  });

  group('layoutDescendants', () {
    test('places root at gen 0 and children below', () {
      // dad -> me, dad -> sis ; me -> kid
      final people = [
        _person('dad', 'Dad'),
        _person('me', 'Me'),
        _person('sis', 'Sis'),
        _person('kid', 'Kid'),
      ];
      final rels = [
        _parentChild('dad', 'me'),
        _parentChild('dad', 'sis'),
        _parentChild('me', 'kid'),
      ];
      final result = layoutDescendants('dad', people, rels);
      expect(result.nodes.length, 4);
      final byId = {for (final n in result.nodes) n.person.id: n};
      expect(byId['dad']!.generation, 0);
      expect(byId['me']!.generation, 1);
      expect(byId['sis']!.generation, 1);
      expect(byId['kid']!.generation, 2);
      // Root sits above its descendants (smaller y).
      expect(byId['dad']!.y, lessThan(byId['me']!.y));
      expect(byId['me']!.y, lessThan(byId['kid']!.y));
    });

    test('single-person tree returns exactly 1 node, no edges', () {
      final result = layoutDescendants('solo', [_person('solo', 'Solo')], []);
      expect(result.nodes.length, 1);
      expect(result.edges.isEmpty, isTrue);
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
    });

    test('is cycle-safe: a parent/child loop does not hang or duplicate', () {
      // Corrupt data: a is parent of b AND b is parent of a.
      final people = [_person('a', 'A'), _person('b', 'B')];
      final rels = [_parentChild('a', 'b'), _parentChild('b', 'a')];
      final result = layoutDescendants('a', people, rels);
      // Each person appears at most once.
      final ids = result.nodes.map((n) => n.person.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.toSet(), {'a', 'b'});
    });
  });

  group('corrupt-data resilience', () {
    test('self-parent edge produces no self-loop edge and no extra node', () {
      // me is wrongly recorded as their own parent.
      final people = [_person('me', 'Me')];
      final rels = [_parentChild('me', 'me')];
      final result = layoutPedigree('me', people, rels);
      expect(result.nodes.map((n) => n.person.id).toList(), ['me']);
      // No edge from me to me.
      expect(result.edges.where((e) => e[0] == e[1]), isEmpty);
    });

    test('duplicate parentChild rows yield a single edge', () {
      final people = [_person('dad', 'Dad'), _person('me', 'Me')];
      final rels = [_parentChild('dad', 'me'), _parentChild('dad', 'me')];
      final result = layoutPedigree('me', people, rels);
      expect(result.edges.where((e) => e[0] == 'dad' && e[1] == 'me'),
          hasLength(1));
    });
  });
}
