import 'package:hive_ce/hive_ce.dart';

part 'timeline_event.g.dart';

@HiveType(typeId: 8)
class TimelineEvent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String createdAt;

  @HiveField(5)
  final String relatedId;

  @HiveField(6)
  final String imagePath;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final List<String> tags;

  @HiveField(9)
  final bool isFeatured;

  @HiveField(10)
  final String repairId;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.relatedId = '',
    this.imagePath = '',
    this.category = '',
    this.tags = const [],
    this.isFeatured = false,
    this.repairId = '',
  });

  DateTime get date =>
      DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);

  TimelineEvent copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? createdAt,
    String? relatedId,
    String? imagePath,
    String? category,
    List<String>? tags,
    bool? isFeatured,
    String? repairId,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      relatedId: relatedId ?? this.relatedId,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      repairId: repairId ?? this.repairId,
    );
  }
}
