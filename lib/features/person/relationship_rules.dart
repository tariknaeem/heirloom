import '../../models.dart';

/// Result of validating a proposed new relationship.
///
/// Pure + deterministic so it can be unit-tested without any DB or widgets.
class RelationshipCheck {
  final bool ok;
  final String? reason;

  const RelationshipCheck.allow()
      : ok = true,
        reason = null;
  const RelationshipCheck.deny(this.reason) : ok = false;
}

/// Returns the set of ancestor ids of [personId] (parents, grandparents …),
/// derived from [rels]. Cycle-safe via a visited set. Does not include
/// [personId] itself unless the data already contains a cycle reaching it.
Set<String> ancestorsOf(String personId, List<Relationship> rels) {
  final parentMap = <String, List<String>>{};
  for (final r in rels) {
    if (r.type == RelType.parentChild) {
      parentMap.putIfAbsent(r.personB, () => []).add(r.personA);
    }
  }
  final result = <String>{};
  final stack = <String>[...?parentMap[personId]];
  while (stack.isNotEmpty) {
    final id = stack.removeLast();
    if (!result.add(id)) continue; // already seen → cycle-safe
    final parents = parentMap[id];
    if (parents != null) stack.addAll(parents);
  }
  return result;
}

/// Validates adding a parent→child `parentChild` relationship.
///
/// Rejects: self-parenting, an exact duplicate, and any edge that would
/// introduce a cycle (making [parentId] a descendant-or-equal of [childId],
/// e.g. a child being set as the parent of their own ancestor).
RelationshipCheck canAddParentChild(
  String parentId,
  String childId,
  List<Relationship> existing,
) {
  if (parentId == childId) {
    return const RelationshipCheck.deny('A person cannot be their own parent.');
  }
  final dup = existing.any((r) =>
      r.type == RelType.parentChild &&
      r.personA == parentId &&
      r.personB == childId);
  if (dup) {
    return const RelationshipCheck.deny('That parent is already linked.');
  }
  // Adding parentId as a parent of childId creates a cycle if parentId is
  // already a descendant of childId (i.e. childId is an ancestor of parentId).
  if (ancestorsOf(parentId, existing).contains(childId)) {
    return const RelationshipCheck.deny(
        'That would create a loop in the tree.');
  }
  // Reverse edge already exists (childId is parent of parentId) → also a cycle.
  final reverse = existing.any((r) =>
      r.type == RelType.parentChild &&
      r.personA == childId &&
      r.personB == parentId);
  if (reverse) {
    return const RelationshipCheck.deny(
        'Those two are already linked the other way around.');
  }
  return const RelationshipCheck.allow();
}

/// Validates adding a `spouse` relationship between two people.
///
/// Rejects self-marriage and an existing spouse link (in either direction).
RelationshipCheck canAddSpouse(
  String aId,
  String bId,
  List<Relationship> existing,
) {
  if (aId == bId) {
    return const RelationshipCheck.deny('A person cannot marry themselves.');
  }
  final dup = existing.any((r) =>
      r.type == RelType.spouse &&
      ((r.personA == aId && r.personB == bId) ||
          (r.personA == bId && r.personB == aId)));
  if (dup) {
    return const RelationshipCheck.deny('They are already linked as spouses.');
  }
  return const RelationshipCheck.allow();
}
