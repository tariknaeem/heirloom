import '../../models.dart';

/// A positioned node in the family tree.
class TreeNode {
  final Person person;
  double x;
  double y;
  int generation;

  TreeNode(this.person, {this.x = 0, this.y = 0, this.generation = 0});
}

/// The result of a layout pass.
class TreeLayoutResult {
  final List<TreeNode> nodes; // positioned nodes
  final List<List<String>> edges; // [parentId, childId] pairs
  final double width;
  final double height;

  TreeLayoutResult(this.nodes, this.edges, this.width, this.height);
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Build a map of personId -> list of parent IDs from [rels].
Map<String, List<String>> _buildParentMap(List<Relationship> rels) {
  final map = <String, List<String>>{};
  for (final r in rels) {
    if (r.type == RelType.parentChild) {
      // personA = parent, personB = child
      map.putIfAbsent(r.personB, () => []).add(r.personA);
    }
  }
  return map;
}

/// BFS upward from [rootId], collecting ancestors grouped by generation.
/// Generation 0 = root, generation 1 = parents, generation 2 = grandparents…
/// Caps at [maxDepth] to stay bounded. Deduplicates by id.
Map<int, List<String>> _collectAncestorsByGeneration(
  String rootId,
  Map<String, List<String>> parentMap, {
  int maxDepth = 6,
}) {
  final result = <int, List<String>>{};
  final visited = <String>{};
  // BFS queue: (personId, generation)
  final queue = <(String, int)>[(rootId, 0)];

  while (queue.isNotEmpty) {
    final (id, gen) = queue.removeAt(0);
    if (visited.contains(id)) continue;
    if (gen > maxDepth) continue;
    visited.add(id);
    result.putIfAbsent(gen, () => []).add(id);

    final parents = parentMap[id] ?? [];
    for (final parentId in parents) {
      if (!visited.contains(parentId)) {
        queue.add((parentId, gen + 1));
      }
    }
  }

  return result;
}

/// Collect all edges where both endpoints are in [nodeSet].
List<List<String>> _collectEdges(
  List<Relationship> rels,
  Set<String> nodeSet,
) {
  final edges = <List<String>>[];
  for (final r in rels) {
    if (r.type == RelType.parentChild) {
      final parent = r.personA;
      final child = r.personB;
      if (nodeSet.contains(parent) && nodeSet.contains(child)) {
        edges.add([parent, child]);
      }
    }
  }
  return edges;
}

// ---------------------------------------------------------------------------
// Public layout functions
// ---------------------------------------------------------------------------

/// Build ANCESTOR (pedigree) layout.
///
/// Root is placed at the **bottom** (generation 0, highest y).
/// Each subsequent generation (parents, grandparents…) goes upward.
/// Nodes in each generation are spread evenly across x, centered.
///
/// [nodeW] / [nodeH] — card dimensions.
/// [gapX] — horizontal gap between cards in the same generation.
/// [gapY] — vertical gap between rows (generations).
TreeLayoutResult layoutPedigree(
  String rootId,
  List<Person> people,
  List<Relationship> rels, {
  double nodeW = 150,
  double nodeH = 84,
  double gapX = 24,
  double gapY = 70,
}) {
  final personMap = {for (final p in people) p.id: p};
  final parentMap = _buildParentMap(rels);
  final byGen = _collectAncestorsByGeneration(rootId, parentMap);

  if (byGen.isEmpty) {
    // No root found — return empty result
    return TreeLayoutResult([], [], 0, 0);
  }

  final maxGen = byGen.keys.reduce((a, b) => a > b ? a : b);

  // Width is determined by the widest generation
  int maxCount = 0;
  for (final ids in byGen.values) {
    if (ids.length > maxCount) maxCount = ids.length;
  }
  final totalWidth = maxCount * (nodeW + gapX) - gapX;
  final totalHeight = (maxGen + 1) * (nodeH + gapY) - gapY;

  // Build positioned nodes.
  // Generation 0 is at y = totalHeight - nodeH (bottom).
  // Higher generations get smaller y values (go up).
  final nodes = <TreeNode>[];
  for (final genEntry in byGen.entries) {
    final gen = genEntry.key;
    final ids = genEntry.value;
    final count = ids.length;
    final rowWidth = count * (nodeW + gapX) - gapX;
    final rowStartX = (totalWidth - rowWidth) / 2;
    final yPos = totalHeight - nodeH - gen * (nodeH + gapY);

    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      final person = personMap[id];
      if (person == null) continue;
      final xPos = rowStartX + i * (nodeW + gapX);
      nodes.add(TreeNode(person, x: xPos, y: yPos, generation: gen));
    }
  }

  final nodeSet = {for (final n in nodes) n.person.id};
  final edges = _collectEdges(rels, nodeSet);

  return TreeLayoutResult(
    nodes,
    edges,
    totalWidth.clamp(nodeW, double.infinity),
    totalHeight.clamp(nodeH, double.infinity),
  );
}

/// Build HORIZONTAL ancestor layout.
///
/// Root at x = 0 (left), each generation steps right.
/// Within a generation, nodes are stacked vertically.
///
/// [nodeW] / [nodeH] — card dimensions.
/// [gapX] — horizontal gap between columns (generations).
/// [gapY] — vertical gap between cards within the same generation.
TreeLayoutResult layoutHorizontal(
  String rootId,
  List<Person> people,
  List<Relationship> rels, {
  double nodeW = 150,
  double nodeH = 84,
  double gapX = 90,
  double gapY = 18,
}) {
  final personMap = {for (final p in people) p.id: p};
  final parentMap = _buildParentMap(rels);
  final byGen = _collectAncestorsByGeneration(rootId, parentMap);

  if (byGen.isEmpty) {
    return TreeLayoutResult([], [], 0, 0);
  }

  final maxGen = byGen.keys.reduce((a, b) => a > b ? a : b);

  // Height is determined by the tallest generation column
  int maxCount = 0;
  for (final ids in byGen.values) {
    if (ids.length > maxCount) maxCount = ids.length;
  }
  final totalWidth = (maxGen + 1) * (nodeW + gapX) - gapX;
  final totalHeight = maxCount * (nodeH + gapY) - gapY;

  // Build positioned nodes.
  // Generation 0 is at x = 0 (left). Higher gens go right.
  // Within a generation, nodes are stacked starting from y = 0.
  final nodes = <TreeNode>[];
  for (final genEntry in byGen.entries) {
    final gen = genEntry.key;
    final ids = genEntry.value;
    final count = ids.length;
    final colHeight = count * (nodeH + gapY) - gapY;
    final colStartY = (totalHeight - colHeight) / 2;
    final xPos = gen * (nodeW + gapX);

    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      final person = personMap[id];
      if (person == null) continue;
      final yPos = colStartY + i * (nodeH + gapY);
      nodes.add(TreeNode(person, x: xPos, y: yPos, generation: gen));
    }
  }

  final nodeSet = {for (final n in nodes) n.person.id};
  final edges = _collectEdges(rels, nodeSet);

  return TreeLayoutResult(
    nodes,
    edges,
    totalWidth.clamp(nodeW, double.infinity),
    totalHeight.clamp(nodeH, double.infinity),
  );
}
