class NotationListItem {
  const NotationListItem({required this.notationId, required this.title});

  factory NotationListItem.fromJson(Map<String, dynamic> json) {
    return NotationListItem(
      notationId: json['notationId'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  final String notationId;
  final String title;
}
