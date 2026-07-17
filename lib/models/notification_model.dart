class NotificationModel {
  final int? id;
  final int serviceId;
  final String title;
  final String body;
  final String scheduledTime;
  final int isRead; 
  final String createdAt;

  NotificationModel({
    this.id,
    required this.serviceId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.isRead = 0,
    required this.createdAt,
  });

  Map toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory NotificationModel.fromMap(Map map) {
    return NotificationModel(
      id: map['id'],
      serviceId: map['serviceId'],
      title: map['title'],
      body: map['body'],
      scheduledTime: map['scheduledTime'],
      isRead: map['isRead'],
      createdAt: map['createdAt'],
    );
  }
}