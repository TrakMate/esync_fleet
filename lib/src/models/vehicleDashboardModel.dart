class VehicleDashboardModel {
  List<Groups>? groups;
  int? totalVehicles;
  int? activeVehicles;
  int? inactiveVehicles;
  VehicleStatusMap? vehicleStatusMap;
  SocSummary? socSummary;
  List<WeeklyVehicleUtilization>? weeklyVehicleUtilization;
  List<MonthlyVehicleUtilization>? monthlyVehicleUtilization;

  VehicleDashboardModel({
    this.groups,
    this.totalVehicles,
    this.activeVehicles,
    this.inactiveVehicles,
    this.vehicleStatusMap,
    this.socSummary,
    this.weeklyVehicleUtilization,
    this.monthlyVehicleUtilization,
  });

  VehicleDashboardModel.fromJson(Map<String, dynamic> json) {
    if (json['groups'] != null) {
      groups = <Groups>[];
      json['groups'].forEach((v) {
        groups!.add(new Groups.fromJson(v));
      });
    }
    totalVehicles = json['totalVehicles'];
    activeVehicles = json['activeVehicles'];
    inactiveVehicles = json['inactiveVehicles'];
    vehicleStatusMap =
        json['vehicleStatusMap'] != null
            ? new VehicleStatusMap.fromJson(json['vehicleStatusMap'])
            : null;
    socSummary =
        json['socSummary'] != null
            ? new SocSummary.fromJson(json['socSummary'])
            : null;
    if (json['weeklyVehicleUtilization'] != null) {
      weeklyVehicleUtilization = <WeeklyVehicleUtilization>[];
      json['weeklyVehicleUtilization'].forEach((v) {
        weeklyVehicleUtilization!.add(new WeeklyVehicleUtilization.fromJson(v));
      });
    }
    if (json['monthlyVehicleUtilization'] != null) {
      monthlyVehicleUtilization = <MonthlyVehicleUtilization>[];
      json['monthlyVehicleUtilization'].forEach((v) {
        monthlyVehicleUtilization!.add(
          new MonthlyVehicleUtilization.fromJson(v),
        );
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groups != null) {
      data['groups'] = this.groups!.map((v) => v.toJson()).toList();
    }
    data['totalVehicles'] = this.totalVehicles;
    data['activeVehicles'] = this.activeVehicles;
    data['inactiveVehicles'] = this.inactiveVehicles;
    if (this.vehicleStatusMap != null) {
      data['vehicleStatusMap'] = this.vehicleStatusMap!.toJson();
    }
    if (this.socSummary != null) {
      data['socSummary'] = this.socSummary!.toJson();
    }
    if (this.weeklyVehicleUtilization != null) {
      data['weeklyVehicleUtilization'] =
          this.weeklyVehicleUtilization!.map((v) => v.toJson()).toList();
    }
    if (this.monthlyVehicleUtilization != null) {
      data['monthlyVehicleUtilization'] =
          this.monthlyVehicleUtilization!.map((v) => v.toJson()).toList();
    }
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

class VehicleStatusMap {
  int? charging;
  int? idle;
  int? disconnected;
  int? discharging;
  int? moving;
  int? stopped;
  int? noncoverage;

  VehicleStatusMap({
    this.charging,
    this.idle,
    this.disconnected,
    this.discharging,
    this.moving,
    this.stopped,
    this.noncoverage,
  });

  VehicleStatusMap.fromJson(Map<String, dynamic> json) {
    charging = json['charging'];
    idle = json['idle'];
    disconnected = json['disconnected'];
    discharging = json['discharging'];
    stopped = json['stopped'];
    moving = json['moving'];
    noncoverage = json['non_coverage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['charging'] = this.charging;
    data['idle'] = this.idle;
    data['disconnected'] = this.disconnected;
    data['disCharging'] = this.discharging;
    data['stopped'] = this.stopped;
    data['moving'] = this.moving;
    data['non_coverage'] = this.noncoverage;
    return data;
  }
}

class SocSummary {
  int? excellent;
  int? good;
  int? moderate;
  int? poor;

  SocSummary({this.excellent, this.good, this.moderate, this.poor});

  SocSummary.fromJson(Map<String, dynamic> json) {
    excellent = json['Excellent'];
    good = json['Good'];
    moderate = json['Moderate'];
    poor = json['Poor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Excellent'] = this.excellent;
    data['Good'] = this.good;
    data['Moderate'] = this.moderate;
    data['Poor'] = this.poor;
    return data;
  }
}

class WeeklyVehicleUtilization {
  String? date;
  String? day;
  int? active;
  int? inactive;

  WeeklyVehicleUtilization({this.date, this.day, this.active, this.inactive});

  WeeklyVehicleUtilization.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    day = json['day'];
    active = json['Active'];
    inactive = json['Inactive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['day'] = this.day;
    data['Active'] = this.active;
    data['Inactive'] = this.inactive;
    return data;
  }
}

class MonthlyVehicleUtilization {
  String? week;
  String? from;
  String? to;
  int? active;
  int? inactive;

  MonthlyVehicleUtilization({
    this.week,
    this.from,
    this.to,
    this.active,
    this.inactive,
  });

  MonthlyVehicleUtilization.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    from = json['from'];
    to = json['to'];
    active = json['Active'];
    inactive = json['Inactive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['week'] = this.week;
    data['from'] = this.from;
    data['to'] = this.to;
    data['Active'] = this.active;
    data['Inactive'] = this.inactive;
    return data;
  }
}
