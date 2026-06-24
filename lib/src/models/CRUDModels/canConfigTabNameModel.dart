class canConfigTabNameModel {
  int? totalCount;
  List<String>? entities;

  canConfigTabNameModel({this.totalCount, this.entities});

  canConfigTabNameModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    entities = json['entities'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    data['entities'] = this.entities;
    return data;
  }
}
