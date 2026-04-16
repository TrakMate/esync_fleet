class LoginFail {
  String? timestamp;
  int? status;
  String? error;
  String? path;

  LoginFail({this.timestamp, this.status, this.error, this.path});

  LoginFail.fromJson(Map<String, dynamic> json) {
    timestamp = json['timestamp'];
    status = json['status'];
    error = json['error'];
    path = json['path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timestamp'] = this.timestamp;
    data['status'] = this.status;
    data['error'] = this.error;
    data['path'] = this.path;
    return data;
  }
}
