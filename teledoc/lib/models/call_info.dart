
class CallInfo {
  String? id;
  String? callerId;
  String? receiverId;
  late bool isCaller;
  

  CallInfo({ this.id, this.callerId, this.receiverId, required this.isCaller });

  CallInfo.fromJson(Map<String, dynamic> json) {
    callerId = json['callerId'];
    receiverId = json['receiverId'];
    isCaller = json['isCaller'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['callerId'] = callerId;
    data['receiverId'] = receiverId;
    data['isCaller'] = isCaller;
    
    return data;
  }

}
