class AlertDashboardModel {
  List<Groups>? groups;
  int? totalAlerts;
  int? criticalAlerts;
  int? nonCriticalAlerts;
  int? attentionNeededVehicles;
  List<Alerts>? alerts;
  // List<WeeklyAlertsGraph>? weeklyAlertsGraph;
  // List<MonthlyAlertsGraph>? monthlyAlertsGraph;

  AlertDashboardModel({
    this.groups,
    this.totalAlerts,
    this.criticalAlerts,
    this.nonCriticalAlerts,
    this.attentionNeededVehicles,
    this.alerts,
    // this.weeklyAlertsGraph,
    // this.monthlyAlertsGraph,
  });

  AlertDashboardModel.fromJson(Map<String, dynamic> json) {
    if (json['groups'] != null) {
      groups = <Groups>[];
      json['groups'].forEach((v) {
        groups!.add(new Groups.fromJson(v));
      });
    }
    totalAlerts = json['totalAlerts'];
    criticalAlerts = json['criticalAlerts'];
    nonCriticalAlerts = json['nonCriticalAlerts'];
    attentionNeededVehicles = json['attentionNeededVehicles'];
    if (json['alerts'] != null) {
      alerts = <Alerts>[];
      json['alerts'].forEach((v) {
        alerts!.add(new Alerts.fromJson(v));
      });
    }
    // if (json['weeklyAlertsGraph'] != null) {
    //   weeklyAlertsGraph = <WeeklyAlertsGraph>[];
    //   json['weeklyAlertsGraph'].forEach((v) {
    //     weeklyAlertsGraph!.add(new WeeklyAlertsGraph.fromJson(v));
    //   });
    // }
    // if (json['monthlyAlertsGraph'] != null) {
    //   monthlyAlertsGraph = <MonthlyAlertsGraph>[];
    //   json['monthlyAlertsGraph'].forEach((v) {
    //     monthlyAlertsGraph!.add(new MonthlyAlertsGraph.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groups != null) {
      data['groups'] = this.groups!.map((v) => v.toJson()).toList();
    }
    data['totalAlerts'] = this.totalAlerts;
    data['criticalAlerts'] = this.criticalAlerts;
    data['nonCriticalAlerts'] = this.nonCriticalAlerts;
    data['attentionNeededVehicles'] = this.attentionNeededVehicles;
    if (this.alerts != null) {
      data['alerts'] = this.alerts!.map((v) => v.toJson()).toList();
    }
    // if (this.weeklyAlertsGraph != null) {
    //   data['weeklyAlertsGraph'] =
    //       this.weeklyAlertsGraph!.map((v) => v.toJson()).toList();
    // }
    // if (this.monthlyAlertsGraph != null) {
    //   data['monthlyAlertsGraph'] =
    //       this.monthlyAlertsGraph!.map((v) => v.toJson()).toList();
    // }
    return data;
  }
}

class Groups {
  String? id;
  String? name;
  String? orgId;

  Groups({this.id, this.name, this.orgId});

  Groups.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    orgId = json['orgId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['orgId'] = this.orgId;
    return data;
  }
}

class Alerts {
  String? imei;
  Null? vehicleNumber;
  String? alertType;
  String? data;
  String? time;
  String? alertCategory;

  Alerts({
    this.imei,
    this.vehicleNumber,
    this.alertType,
    this.data,
    this.time,
    this.alertCategory,
  });

  Alerts.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    vehicleNumber = json['vehicleNumber'];
    alertType = json['alertType'];
    data = json['data'];
    time = json['time'];
    alertCategory = json['alertCategory'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imei'] = this.imei;
    data['vehicleNumber'] = this.vehicleNumber;
    data['alertType'] = this.alertType;
    data['data'] = this.data;
    data['time'] = this.time;
    data['alertCategory'] = this.alertCategory;
    return data;
  }
}

// class WeeklyAlertsGraph {
//   String? date;
//   int? nonCritical;
//   int? critical;
//   String? day;

//   WeeklyAlertsGraph({this.date, this.nonCritical, this.critical, this.day});

//   WeeklyAlertsGraph.fromJson(Map<String, dynamic> json) {
//     date = json['date'];
//     nonCritical = json['Non-critical'];
//     critical = json['Critical'];
//     day = json['day'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['date'] = this.date;
//     data['Non-critical'] = this.nonCritical;
//     data['Critical'] = this.critical;
//     data['day'] = this.day;
//     return data;
//   }
// }

// class MonthlyAlertsGraph {
//   String? week;
//   String? from;
//   String? to;
//   int? critical;
//   int? nonCritical;

//   MonthlyAlertsGraph({
//     this.week,
//     this.from,
//     this.to,
//     this.critical,
//     this.nonCritical,
//   });

//   MonthlyAlertsGraph.fromJson(Map<String, dynamic> json) {
//     week = json['week'];
//     from = json['from'];
//     to = json['to'];
//     critical = json['Critical'];
//     nonCritical = json['Non-critical'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['week'] = this.week;
//     data['from'] = this.from;
//     data['to'] = this.to;
//     data['Critical'] = this.critical;
//     data['Non-critical'] = this.nonCritical;
//     return data;
//   }
// }
