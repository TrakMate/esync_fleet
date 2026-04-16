class DashboardDetailModel {
  List<Groups>? groups;
  int? totalVehicles;
  int? activeVehicle;
  int? inactiveVehicle;
  int? totalAlerts;
  int? critical;
  int? nonCritical;
  int? faults;
  int? totalTrips;
  int? completedTrips;
  int? ongoingTrips;
  double? averageTrips;
  double? consumedFuel;
  double? totalDistance;
  double? totalOperateHr;
  double? todayDistanceKm;
  double? todayOperHr;
  double? yesterdayDistanceKm;
  double? yesterdayOperHr;
  VehicleStatus? vehicleStatus;
  List<AllAlerts>? allAlerts;
  List<AlertsGraph>? alertsGraph;
  List<AlertGraphforMonth>? alertGraphforMonth;
  List<TripsGraph>? tripsGraph;
  List<TripsGraphforMonth>? tripsGraphforMonth;
  List<VehicleutliGraph>? vehicleutliGraph;
  List<VehicleutliGraphforMonth>? vehicleutliGraphforMonth;
  Bms? bms;

  DashboardDetailModel({
    this.groups,
    this.totalVehicles,
    this.activeVehicle,
    this.inactiveVehicle,
    this.totalAlerts,
    this.critical,
    this.nonCritical,
    this.faults,
    this.totalTrips,
    this.completedTrips,
    this.ongoingTrips,
    this.averageTrips,
    this.consumedFuel,
    this.totalDistance,
    this.totalOperateHr,
    this.todayDistanceKm,
    this.todayOperHr,
    this.yesterdayDistanceKm,
    this.yesterdayOperHr,
    this.vehicleStatus,
    this.allAlerts,
    this.alertsGraph,
    this.alertGraphforMonth,
    this.tripsGraph,
    this.tripsGraphforMonth,
    this.vehicleutliGraph,
    this.vehicleutliGraphforMonth,
    this.bms,
  });

  DashboardDetailModel.fromJson(Map<String, dynamic> json) {
    if (json['groups'] != null) {
      groups = <Groups>[];
      json['groups'].forEach((v) {
        groups!.add(new Groups.fromJson(v));
      });
    }
    totalVehicles = json['totalVehicles'];
    activeVehicle = json['activeVehicle'];
    inactiveVehicle = json['inactiveVehicle'];
    totalAlerts = json['totalAlerts'];
    critical = json['critical'];
    nonCritical = json['non_critical'];
    faults = json['faults'];
    totalTrips = json['total_trips'];
    completedTrips = json['completed_trips'];
    ongoingTrips = json['ongoing_trips'];
    averageTrips = json['average_trips'];
    consumedFuel = json['consumed_Fuel'];
    totalDistance = json['total_Distance'];
    totalOperateHr = json['total_Operate_hr'];
    todayDistanceKm = json['today_Distance_km'];
    todayOperHr = json['today_oper_hr'];
    yesterdayDistanceKm = json['yesterday_Distance_km'];
    yesterdayOperHr = json['yesterday_oper_hr'];
    vehicleStatus =
        json['vehicle_status'] != null
            ? new VehicleStatus.fromJson(json['vehicle_status'])
            : null;
    if (json['allAlerts'] != null) {
      allAlerts = <AllAlerts>[];
      json['allAlerts'].forEach((v) {
        allAlerts!.add(new AllAlerts.fromJson(v));
      });
    }
    if (json['alertsGraph'] != null) {
      alertsGraph = <AlertsGraph>[];
      json['alertsGraph'].forEach((v) {
        alertsGraph!.add(new AlertsGraph.fromJson(v));
      });
    }
    if (json['alertGraphforMonth'] != null) {
      alertGraphforMonth = <AlertGraphforMonth>[];
      json['alertGraphforMonth'].forEach((v) {
        alertGraphforMonth!.add(new AlertGraphforMonth.fromJson(v));
      });
    }
    if (json['tripsGraph'] != null) {
      tripsGraph = <TripsGraph>[];
      json['tripsGraph'].forEach((v) {
        tripsGraph!.add(new TripsGraph.fromJson(v));
      });
    }
    if (json['tripsGraphforMonth'] != null) {
      tripsGraphforMonth = <TripsGraphforMonth>[];
      json['tripsGraphforMonth'].forEach((v) {
        tripsGraphforMonth!.add(new TripsGraphforMonth.fromJson(v));
      });
    }
    if (json['vehicleutliGraph'] != null) {
      vehicleutliGraph = <VehicleutliGraph>[];
      json['vehicleutliGraph'].forEach((v) {
        vehicleutliGraph!.add(new VehicleutliGraph.fromJson(v));
      });
    }
    if (json['vehicleutliGraphforMonth'] != null) {
      vehicleutliGraphforMonth = <VehicleutliGraphforMonth>[];
      json['vehicleutliGraphforMonth'].forEach((v) {
        vehicleutliGraphforMonth!.add(new VehicleutliGraphforMonth.fromJson(v));
      });
    }
    bms = json['bms'] != null ? new Bms.fromJson(json['bms']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groups != null) {
      data['groups'] = this.groups!.map((v) => v.toJson()).toList();
    }
    data['totalVehicles'] = this.totalVehicles;
    data['activeVehicle'] = this.activeVehicle;
    data['inactiveVehicle'] = this.inactiveVehicle;
    data['totalAlerts'] = this.totalAlerts;
    data['critical'] = this.critical;
    data['non_critical'] = this.nonCritical;
    data['faults'] = this.faults;
    data['total_trips'] = this.totalTrips;
    data['completed_trips'] = this.completedTrips;
    data['ongoing_trips'] = this.ongoingTrips;
    data['average_trips'] = this.averageTrips;
    data['consumed_Fuel'] = this.consumedFuel;
    data['total_Distance'] = this.totalDistance;
    data['total_Operate_hr'] = this.totalOperateHr;
    data['today_Distance_km'] = this.todayDistanceKm;
    data['today_oper_hr'] = this.todayOperHr;
    data['yesterday_Distance_km'] = this.yesterdayDistanceKm;
    data['yesterday_oper_hr'] = this.yesterdayOperHr;
    if (this.vehicleStatus != null) {
      data['vehicle_status'] = this.vehicleStatus!.toJson();
    }
    if (this.allAlerts != null) {
      data['allAlerts'] = this.allAlerts!.map((v) => v.toJson()).toList();
    }
    if (this.alertsGraph != null) {
      data['alertsGraph'] = this.alertsGraph!.map((v) => v.toJson()).toList();
    }
    if (this.alertGraphforMonth != null) {
      data['alertGraphforMonth'] =
          this.alertGraphforMonth!.map((v) => v.toJson()).toList();
    }
    if (this.tripsGraph != null) {
      data['tripsGraph'] = this.tripsGraph!.map((v) => v.toJson()).toList();
    }
    if (this.tripsGraphforMonth != null) {
      data['tripsGraphforMonth'] =
          this.tripsGraphforMonth!.map((v) => v.toJson()).toList();
    }
    if (this.vehicleutliGraph != null) {
      data['vehicleutliGraph'] =
          this.vehicleutliGraph!.map((v) => v.toJson()).toList();
    }
    if (this.vehicleutliGraphforMonth != null) {
      data['vehicleutliGraphforMonth'] =
          this.vehicleutliGraphforMonth!.map((v) => v.toJson()).toList();
    }
    if (this.bms != null) {
      data['bms'] = this.bms!.toJson();
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

class VehicleStatus {
  int? charging;
  int? idle;
  int? disconnected;
  int? disCharging;
  int? moving;
  int? stopped;
  int? noncoverage;

  VehicleStatus({
    this.charging,
    this.idle,
    this.disconnected,
    this.disCharging,
    this.moving,
    this.stopped,
    this.noncoverage,
  });

  VehicleStatus.fromJson(Map<String, dynamic> json) {
    charging = json['Charging'];
    idle = json['Idle'];
    disconnected = json['Disconnected'];
    disCharging = json['DisCharging'];
    stopped = json['Stopped'];
    moving = json['Moving'];
    noncoverage = json['Non Coverage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Charging'] = this.charging;
    data['Idle'] = this.idle;
    data['Disconnected'] = this.disconnected;
    data['DisCharging'] = this.disCharging;
    data['Stopped'] = this.stopped;
    data['Moving'] = this.moving;
    data['Non Coverage'] = this.noncoverage;
    return data;
  }
}

class AllAlerts {
  String? imei;
  String? vehicleNumber;
  String? alertType;
  String? data;
  String? time;
  String? alertCategory;

  AllAlerts({
    this.imei,
    this.vehicleNumber,
    this.alertType,
    this.data,
    this.time,
    this.alertCategory,
  });

  AllAlerts.fromJson(Map<String, dynamic> json) {
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

class AlertsGraph {
  String? date;
  int? nonCritical;
  int? critical;
  String? day;

  AlertsGraph({this.date, this.nonCritical, this.critical, this.day});

  AlertsGraph.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    nonCritical = json['Non-critical'];
    critical = json['Critical'];
    day = json['day'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['Non-critical'] = this.nonCritical;
    data['Critical'] = this.critical;
    data['day'] = this.day;
    return data;
  }
}

class AlertGraphforMonth {
  String? week;
  int? nonCritical;
  String? from;
  int? critical;
  String? to;

  AlertGraphforMonth({
    this.week,
    this.nonCritical,
    this.from,
    this.critical,
    this.to,
  });

  AlertGraphforMonth.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    nonCritical = json['Non-critical'];
    from = json['from'];
    critical = json['Critical'];
    to = json['to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['week'] = this.week;
    data['Non-critical'] = this.nonCritical;
    data['from'] = this.from;
    data['Critical'] = this.critical;
    data['to'] = this.to;
    return data;
  }
}

class TripsGraph {
  String? date;
  String? day;
  int? trips;
  String? distance;
  String? operatedHours;

  TripsGraph({
    this.date,
    this.day,
    this.trips,
    this.distance,
    this.operatedHours,
  });

  TripsGraph.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    day = json['day'];
    trips = json['Trips'];
    distance = json['Distance'];
    operatedHours = json['Operated_Hours'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['day'] = this.day;
    data['Trips'] = this.trips;
    data['Distance'] = this.distance;
    data['Operated_Hours'] = this.operatedHours;
    return data;
  }
}

class TripsGraphforMonth {
  String? week;
  String? from;
  String? to;
  int? trips;
  String? distance;
  String? operatedHours;

  TripsGraphforMonth({
    this.week,
    this.from,
    this.to,
    this.trips,
    this.distance,
    this.operatedHours,
  });

  TripsGraphforMonth.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    from = json['from'];
    to = json['to'];
    trips = json['Trips'];
    distance = json['Distance'];
    operatedHours = json['Operated_Hours'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['week'] = this.week;
    data['from'] = this.from;
    data['to'] = this.to;
    data['Trips'] = this.trips;
    data['Distance'] = this.distance;
    data['Operated_Hours'] = this.operatedHours;
    return data;
  }
}

class VehicleutliGraph {
  String? date;
  String? day;
  int? active;
  int? inactive;

  VehicleutliGraph({this.date, this.day, this.active, this.inactive});

  VehicleutliGraph.fromJson(Map<String, dynamic> json) {
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

class VehicleutliGraphforMonth {
  String? week;
  String? from;
  String? to;
  int? active;
  int? inactive;

  VehicleutliGraphforMonth({
    this.week,
    this.from,
    this.to,
    this.active,
    this.inactive,
  });

  VehicleutliGraphforMonth.fromJson(Map<String, dynamic> json) {
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

class Bms {
  int? excellent;
  int? good;
  int? moderate;
  int? poor;

  Bms({this.excellent, this.good, this.moderate, this.poor});

  Bms.fromJson(Map<String, dynamic> json) {
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
