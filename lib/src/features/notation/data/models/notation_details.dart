class NotationDetails {
  const NotationDetails({
    required this.notationId,
    required this.title,
    required this.content,
  });

  factory NotationDetails.fromJson(Map<String, dynamic> json) {
    return NotationDetails(
      notationId: json['notationId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  final String notationId;
  final String title;
  final String content;
}
