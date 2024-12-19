

class NotificationBody {
  int? orderId;
  String? type;
  String? messageKey;


  NotificationBody({
    this.orderId,
    this.type,
    this.messageKey
  });

  NotificationBody.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    type = json['type'];
    messageKey = json['message_key'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['type'] = type;
    data['message_key'] = messageKey;
    return data;
  }


}
