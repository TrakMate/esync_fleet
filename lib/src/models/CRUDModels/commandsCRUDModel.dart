class CommandsCRUDModel {
  int? totalCount;
  List<CommandEntities>? entities;

  CommandsCRUDModel({this.totalCount, this.entities});

  CommandsCRUDModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['entities'] != null) {
      entities = <CommandEntities>[];
      json['entities'].forEach((v) {
        entities!.add(new CommandEntities.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    if (this.entities != null) {
      data['entities'] = this.entities!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CommandEntities {
  String? id;
  String? imei;
  String? type;
  String? commandSent;
  String? dataReceived;
  String? date;
  String? userId;
  String? orgId;

  CommandEntities({
    this.id,
    this.imei,
    this.type,
    this.commandSent,
    this.dataReceived,
    this.date,
    this.userId,
    this.orgId,
  });

  CommandEntities.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    imei = json['imei'];
    type = json['type'];
    commandSent = json['commandSent'];
    dataReceived = json['dataReceived'];
    date = json['date'];
    userId = json['userId'];
    orgId = json['orgId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['imei'] = this.imei;
    data['type'] = this.type;
    data['commandSent'] = this.commandSent;
    data['dataReceived'] = this.dataReceived;
    data['date'] = this.date;
    data['userId'] = this.userId;
    data['orgId'] = this.orgId;
    return data;
  }
}
