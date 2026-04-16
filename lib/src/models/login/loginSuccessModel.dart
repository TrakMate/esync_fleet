class LoginSuccess {
  String? accessToken;
  Null? fullName;
  Null? userId;
  Null? profileImage;
  Null? role;
  int? orgDeviceType;

  LoginSuccess({
    this.accessToken,
    this.fullName,
    this.userId,
    this.profileImage,
    this.role,
    this.orgDeviceType,
  });

  LoginSuccess.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'];
    fullName = json['fullName'];
    userId = json['userId'];
    profileImage = json['profileImage'];
    role = json['role'];
    orgDeviceType = json['orgDeviceType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['accessToken'] = this.accessToken;
    data['fullName'] = this.fullName;
    data['userId'] = this.userId;
    data['profileImage'] = this.profileImage;
    data['role'] = this.role;
    data['orgDeviceType'] = this.orgDeviceType;
    return data;
  }
}
