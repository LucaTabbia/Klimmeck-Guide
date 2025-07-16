class KGNotification {
  KGNotification({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory KGNotification.fromJson(Map<String, dynamic> json) =>
      KGNotification(
        title: json["title"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
  };
}