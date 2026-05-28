import 'package:uuid/uuid.dart';
import '../../models.dart';

class PersonDraft {
  String displayName;
  String? given;
  String? family;
  String? gender;
  String? birthDate;
  String? deathDate;
  bool isLiving;
  String? photoPath;
  String? bio;

  PersonDraft({
    this.displayName = '',
    this.given,
    this.family,
    this.gender,
    this.birthDate,
    this.deathDate,
    this.isLiving = true,
    this.photoPath,
    this.bio,
  });

  factory PersonDraft.from(Person p) => PersonDraft(
        displayName: p.displayName,
        given: p.given,
        family: p.family,
        gender: p.gender,
        birthDate: p.birthDate,
        deathDate: p.deathDate,
        isLiving: p.isLiving,
        photoPath: p.photoPath,
        bio: p.bio,
      );

  String? validate() =>
      displayName.trim().isEmpty ? 'Name is required' : null;

  Person toPerson({String? id}) => Person(
        id: id ?? const Uuid().v4(),
        displayName: displayName.trim(),
        given: given,
        family: family,
        gender: gender,
        birthDate: birthDate,
        deathDate: deathDate,
        isLiving: isLiving,
        photoPath: photoPath,
        bio: bio,
      );
}
