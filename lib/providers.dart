import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db.dart';
import 'models.dart';
import 'repository.dart';

/// Override in tests with InMemoryFamilyRepository.
final repositoryProvider = Provider<FamilyRepository>(
  (ref) => SqfliteFamilyRepository(),
);

/// Bump to force people/relationship providers to refetch after writes.
final dataVersionProvider = StateProvider<int>((ref) => 0);

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(repositoryProvider);
  await repo.init();
  return repo.allPeople();
});

final relationshipsProvider = FutureProvider<List<Relationship>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(repositoryProvider);
  await repo.init();
  return repo.allRelationships();
});
