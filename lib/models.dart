class Person {
  final String id;
  final String displayName;
  final String? given;
  final String? family;
  final String? gender; // 'male'|'female'|'other'|null
  final String? birthDate; // ISO yyyy-MM-dd or null
  final String? deathDate;
  final bool isLiving;
  final String? photoPath;
  final String? bio;

  const Person({
    required this.id,
    required this.displayName,
    this.given,
    this.family,
    this.gender,
    this.birthDate,
    this.deathDate,
    this.isLiving = true,
    this.photoPath,
    this.bio,
  });

  Person copyWith({
    String? displayName,
    String? given,
    String? family,
    String? gender,
    String? birthDate,
    String? deathDate,
    bool? isLiving,
    String? photoPath,
    String? bio,
  }) =>
      Person(
        id: id,
        displayName: displayName ?? this.displayName,
        given: given ?? this.given,
        family: family ?? this.family,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        deathDate: deathDate ?? this.deathDate,
        isLiving: isLiving ?? this.isLiving,
        photoPath: photoPath ?? this.photoPath,
        bio: bio ?? this.bio,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'displayName': displayName,
        'given': given,
        'family': family,
        'gender': gender,
        'birthDate': birthDate,
        'deathDate': deathDate,
        'isLiving': isLiving ? 1 : 0,
        'photoPath': photoPath,
        'bio': bio,
      };

  static Person fromMap(Map<String, Object?> m) => Person(
        id: m['id'] as String,
        displayName: m['displayName'] as String,
        given: m['given'] as String?,
        family: m['family'] as String?,
        gender: m['gender'] as String?,
        birthDate: m['birthDate'] as String?,
        deathDate: m['deathDate'] as String?,
        isLiving: (m['isLiving'] as int? ?? 1) == 1,
        photoPath: m['photoPath'] as String?,
        bio: m['bio'] as String?,
      );
}

enum RelType { parentChild, spouse }

class Relationship {
  final String id;
  final RelType type;
  final String personA; // for parentChild: A = parent, B = child
  final String personB;

  const Relationship({
    required this.id,
    required this.type,
    required this.personA,
    required this.personB,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'personA': personA,
        'personB': personB,
      };

  static Relationship fromMap(Map<String, Object?> m) => Relationship(
        id: m['id'] as String,
        type: RelType.values.firstWhere((t) => t.name == m['type']),
        personA: m['personA'] as String,
        personB: m['personB'] as String,
      );
}

class LifeEvent {
  final String id;
  final String personId;
  final String type; // birth|death|marriage|custom
  final String? date;
  final String? place;
  final String? note;

  const LifeEvent({
    required this.id,
    required this.personId,
    required this.type,
    this.date,
    this.place,
    this.note,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'personId': personId,
        'type': type,
        'date': date,
        'place': place,
        'note': note,
      };

  static LifeEvent fromMap(Map<String, Object?> m) => LifeEvent(
        id: m['id'] as String,
        personId: m['personId'] as String,
        type: m['type'] as String,
        date: m['date'] as String?,
        place: m['place'] as String?,
        note: m['note'] as String?,
      );
}

class Story {
  final String id;
  final String personId;
  final String title;
  final String body;
  final int createdAt;

  const Story({
    required this.id,
    required this.personId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'personId': personId,
        'title': title,
        'body': body,
        'createdAt': createdAt,
      };

  static Story fromMap(Map<String, Object?> m) => Story(
        id: m['id'] as String,
        personId: m['personId'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        createdAt: m['createdAt'] as int,
      );
}

class MediaItem {
  final String id;
  final String personId;
  final String filePath;
  final String? caption;

  const MediaItem({
    required this.id,
    required this.personId,
    required this.filePath,
    this.caption,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'personId': personId,
        'filePath': filePath,
        'caption': caption,
      };

  static MediaItem fromMap(Map<String, Object?> m) => MediaItem(
        id: m['id'] as String,
        personId: m['personId'] as String,
        filePath: m['filePath'] as String,
        caption: m['caption'] as String?,
      );
}
