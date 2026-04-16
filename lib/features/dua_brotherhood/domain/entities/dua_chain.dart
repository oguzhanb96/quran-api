class DuaChain {
  const DuaChain({
    required this.id,
    required this.title,
    required this.targetCount,
    required this.currentCount,
    required this.participants,
    required this.isCompleted,
    this.description,
    this.createdAt,
    this.category,
  });

  final String id;
  final String title;
  final int targetCount;
  final int currentCount;
  final int participants;
  final bool isCompleted;
  final String? description;
  final DateTime? createdAt;
  final String? category;
}
