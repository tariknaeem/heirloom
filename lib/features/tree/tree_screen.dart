import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'person_card.dart';
import 'tree_layout.dart';

enum _TreeLayout { pedigree, horizontal, list }

/// The signature family-tree screen.
///
/// - AppBar with a 3-way layout switcher (Pedigree / Horizontal / List).
/// - Pedigree & Horizontal: pan+pinch `InteractiveViewer` with `Stack`-based
///   positioned cards and a `CustomPaint` edge layer.
/// - List: simple `ListView` of all people.
/// - `focusId` state tracks which person is the current root/focus.
/// - Single-tap on a card = re-focus (update root + pan); open-icon tap or
///   second tap on already-focused card = call [onOpenProfile].
class TreeScreen extends ConsumerStatefulWidget {
  final void Function(String personId)? onOpenProfile;

  const TreeScreen({super.key, this.onOpenProfile});

  @override
  ConsumerState<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends ConsumerState<TreeScreen> {
  _TreeLayout _layout = _TreeLayout.pedigree;
  String? _focusId;

  // ── card geometry ─────────────────────────────────────────────────────────
  static const double _cardW = 150;
  static const double _cardH = 84;

  // ── layout switching ──────────────────────────────────────────────────────

  Widget _layoutSwitcher() {
    return SegmentedButton<_TreeLayout>(
      segments: const [
        ButtonSegment(
          value: _TreeLayout.pedigree,
          label: Text('Pedigree'),
          icon: Icon(Icons.account_tree_rounded),
        ),
        ButtonSegment(
          value: _TreeLayout.horizontal,
          label: Text('Horizontal'),
          icon: Icon(Icons.swap_horiz_rounded),
        ),
        ButtonSegment(
          value: _TreeLayout.list,
          label: Text('List'),
          icon: Icon(Icons.list_rounded),
        ),
      ],
      selected: {_layout},
      onSelectionChanged: (val) =>
          setState(() => _layout = val.first),
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ── empty state ───────────────────────────────────────────────────────────

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom_rounded,
                size: 64, color: kMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text(
              'Add your first family member',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kInk,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your family tree will appear here once\nyou add someone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ── list view ─────────────────────────────────────────────────────────────

  Widget _buildListView(List<Person> people) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: people.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final person = people[i];
        return PersonCard(
          person: person,
          width: double.infinity,
          height: _cardH,
          isFocused: person.id == _focusId,
          onTap: () => setState(() => _focusId = person.id),
          onOpenProfile: widget.onOpenProfile != null
              ? () => widget.onOpenProfile!(person.id)
              : null,
        );
      },
    );
  }

  // ── tree view (pedigree or horizontal) ────────────────────────────────────

  Widget _buildTreeView(
    List<Person> people,
    List<Relationship> rels,
    bool isPedigree,
  ) {
    final focusId = _focusId ?? (people.isEmpty ? null : people.first.id);
    if (focusId == null) return _empty();

    final result = isPedigree
        ? layoutPedigree(focusId, people, rels,
            nodeW: _cardW, nodeH: _cardH)
        : layoutHorizontal(focusId, people, rels,
            nodeW: _cardW, nodeH: _cardH);

    if (result.nodes.isEmpty) {
      // Fallback: just show the focus person alone
      final person = people.firstWhere(
        (p) => p.id == focusId,
        orElse: () => people.first,
      );
      final singleResult = TreeLayoutResult(
        [TreeNode(person, x: 0, y: 0, generation: 0)],
        [],
        _cardW,
        _cardH,
      );
      return _treeCanvas(singleResult, isPedigree);
    }

    return _treeCanvas(result, isPedigree);
  }

  Widget _treeCanvas(TreeLayoutResult result, bool isPedigree) {
    // Build a node lookup for edge painting
    final nodeMap = {for (final n in result.nodes) n.person.id: n};

    final canvasWidth = result.width + _cardW;
    final canvasHeight = result.height + _cardH;
    const padding = 32.0;

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.3,
      maxScale: 2.5,
      child: Container(
        color: kBg,
        width: canvasWidth + padding * 2,
        height: canvasHeight + padding * 2,
        child: Stack(
          children: [
            // Edge layer (behind cards)
            Positioned.fill(
              child: CustomPaint(
                painter: _EdgePainter(
                  nodes: nodeMap,
                  edges: result.edges,
                  cardW: _cardW,
                  cardH: _cardH,
                  offsetX: padding,
                  offsetY: padding,
                ),
              ),
            ),
            // Card nodes
            for (final node in result.nodes)
              Positioned(
                left: node.x + padding,
                top: node.y + padding,
                child: PersonCard(
                  person: node.person,
                  width: _cardW,
                  height: _cardH,
                  isFocused: node.person.id == _focusId,
                  onTap: () {
                    if (_focusId == node.person.id) {
                      // Already focused → open profile
                      widget.onOpenProfile?.call(node.person.id);
                    } else {
                      setState(() => _focusId = node.person.id);
                    }
                  },
                  onOpenProfile: widget.onOpenProfile != null
                      ? () => widget.onOpenProfile!(node.person.id)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final relsAsync = ref.watch(relationshipsProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Family'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _layoutSwitcher(),
          ),
        ),
      ),
      body: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading people: $e',
              style: const TextStyle(color: kMuted)),
        ),
        data: (people) {
          if (people.isEmpty) return _empty();

          // Set default focus to the person with no parents (likely root)
          if (_focusId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final relsSnapshot = ref.read(relationshipsProvider).valueOrNull;
              if (relsSnapshot != null) {
                final childIds = {
                  for (final r in relsSnapshot)
                    if (r.type == RelType.parentChild) r.personB
                };
                final root = people.firstWhere(
                  (p) => !childIds.contains(p.id),
                  orElse: () => people.first,
                );
                if (mounted) setState(() => _focusId = root.id);
              } else {
                if (mounted) setState(() => _focusId = people.first.id);
              }
            });
          }

          if (_layout == _TreeLayout.list) {
            return _buildListView(people);
          }

          return relsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error loading relationships: $e',
                  style: const TextStyle(color: kMuted)),
            ),
            data: (rels) => _buildTreeView(
              people,
              rels,
              _layout == _TreeLayout.pedigree,
            ),
          );
        },
      ),
    );
  }
}

// ── Edge painter ─────────────────────────────────────────────────────────────

/// Draws lines from parent card centre-bottom to child card centre-top
/// (for pedigree-style) — actually we draw mid-point connectors regardless
/// of orientation: from the mid-right of the parent box to mid-left of the
/// child box if the parent is to the right (horizontal), or from bottom-mid
/// to top-mid otherwise.  We use a simple elbow (two segments).
class _EdgePainter extends CustomPainter {
  final Map<String, TreeNode> nodes;
  final List<List<String>> edges;
  final double cardW;
  final double cardH;
  final double offsetX;
  final double offsetY;

  const _EdgePainter({
    required this.nodes,
    required this.edges,
    required this.cardW,
    required this.cardH,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = kLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = kAccent.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      if (edge.length < 2) continue;
      final parentNode = nodes[edge[0]];
      final childNode = nodes[edge[1]];
      if (parentNode == null || childNode == null) continue;

      // Determine orientation by checking whether the parent generation
      // is higher (pedigree, vertical layout) or to the right (horizontal).
      final parentGen = parentNode.generation;
      final childGen = childNode.generation;

      final px = parentNode.x + offsetX;
      final py = parentNode.y + offsetY;
      final cx = childNode.x + offsetX;
      final cy = childNode.y + offsetY;

      final paint = (parentGen > 0 || childGen > 0) ? linePaint : accentPaint;

      if ((parentNode.x - childNode.x).abs() >
          (parentNode.y - childNode.y).abs()) {
        // Horizontal layout: connect right edge of left node to left edge
        // of right node. Parent gen > child gen means parent is to the right.
        final (fromX, fromY, toX, toY) = parentNode.x > childNode.x
            ? (
                cx + cardW,
                cy + cardH / 2,
                px,
                py + cardH / 2,
              )
            : (
                px + cardW,
                py + cardH / 2,
                cx,
                cy + cardH / 2,
              );
        final midX = (fromX + toX) / 2;
        final path = Path()
          ..moveTo(fromX, fromY)
          ..lineTo(midX, fromY)
          ..lineTo(midX, toY)
          ..lineTo(toX, toY);
        canvas.drawPath(path, paint);
      } else {
        // Vertical (pedigree) layout: connect bottom of child (lower gen)
        // to top of parent (higher gen).
        // child gen=0 is at bottom, parent gen=1 is above.
        final (fromX, fromY, toX, toY) = childNode.y > parentNode.y
            ? (
                cx + cardW / 2,
                cy,
                px + cardW / 2,
                py + cardH,
              )
            : (
                px + cardW / 2,
                py,
                cx + cardW / 2,
                cy + cardH,
              );
        final midY = (fromY + toY) / 2;
        final path = Path()
          ..moveTo(fromX, fromY)
          ..lineTo(fromX, midY)
          ..lineTo(toX, midY)
          ..lineTo(toX, toY);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.edges != edges || old.nodes != nodes;
}
