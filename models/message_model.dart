class MessageModel {
  final String type;
  final String? text;
  final String? imagePath;

  MessageModel({
    required this.type,
    this.text,
    this.imagePath,
  });
}