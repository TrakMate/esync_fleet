class TripDashboardModel {
  List<Groups>? groups;
  int? totalTrips;
  int? completedTrips;
  int? ongoingTrips;
  double? avgTripsPerDay;
  double? totalEnergyConsumed;
  double? totalDistanceKm;
  double? totalOperationalDuration;
  double? todayDistanceKm;
  double? todayOperationalHours;
  double? yesterdayDistanceKm;
  double? yesterdayOperationalHours;
  Null? weeklyTripsGraph;
  Null? monthlyTripsGraph;

  TripDashboardModel({
    this.groups,
    this.totalTrips,
    this.completedTrips,
    this.ongoingTrips,
    this.avgTripsPerDay,
    this.totalEnergyConsumed,
    this.totalDistanceKm,
    this.totalOperationalDuration,
    this.todayDistanceKm,
    this.todayOperationalHours,
    this.yesterdayDistanceKm,
    this.yesterdayOperationalHours,
    this.weeklyTripsGraph,
    this.monthlyTripsGraph,
  });

  TripDashboardModel.fromJson(Map<String, dynamic> json) {
    if (json['groups'] != null) {
      groups = <Groups>[];
      json['groups'].forEach((v) {
        groups!.add(new Groups.fromJson(v));
      });
    }
    totalTrips = json['totalTrips'];
    completedTrips = json['completedTrips'];
    ongoingTrips = json['ongoingTrips'];
    avgTripsPerDay = json['avgTripsPerDay'];
    totalEnergyConsumed = json['totalEnergyConsumed'];
    totalDistanceKm = json['totalDistanceKm'];
    totalOperationalDuration = json['totalOperationalDuration'];
    todayDistanceKm = json['todayDistanceKm'];
    todayOperationalHours = json['todayOperationalHours'];
    yesterdayDistanceKm = json['yesterdayDistanceKm'];
    yesterdayOperationalHours = json['yesterdayOperationalHours'];
    // if (json['weeklyTripsGraph'] != null) {
    //   weeklyTripsGraph = <WeeklyTripsGraph>[];
    //   json['weeklyTripsGraph'].forEach((v) {
    //     weeklyTripsGraph!.add(new WeeklyTripsGraph.fromJson(v));
    //   });
    // }
    // if (json['monthlyTripsGraph'] != null) {
    //   monthlyTripsGraph = <MonthlyTripsGraph>[];
    //   json['monthlyTripsGraph'].forEach((v) {
    //     monthlyTripsGraph!.add(new MonthlyTripsGraph.fromJson(v));
    //   });
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groups != null) {
      data['groups'] = this.groups!.map((v) => v.toJson()).toList();
    }
    data['totalTrips'] = this.totalTrips;
    data['completedTrips'] = this.completedTrips;
    data['ongoingTrips'] = this.ongoingTrips;
    data['avgTripsPerDay'] = this.avgTripsPerDay;
    data['totalEnergyConsumed'] = this.totalEnergyConsumed;
    data['totalDistanceKm'] = this.totalDistanceKm;
    data['totalOperationalDuration'] = this.totalOperationalDuration;
    data['todayDistanceKm'] = this.todayDistanceKm;
    data['todayOperationalHours'] = this.todayOperationalHours;
    data['yesterdayDistanceKm'] = this.yesterdayDistanceKm;
    data['yesterdayOperationalHours'] = this.yesterdayOperationalHours;
    // if (this.weeklyTripsGraph != null) {
    //   data['weeklyTripsGraph'] =
    //       this.weeklyTripsGraph!.map((v) => v.toJson()).toList();
    // }
    // if (this.monthlyTripsGraph != null) {
    //   data['monthlyTripsGraph'] =
    //       this.monthlyTripsGraph!.map((v) => v.toJson()).toList();
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

class WeeklyTripsGraph {
  String? date;
  String? day;
  int? trips;
  String? distance;
  String? operatedHours;

  WeeklyTripsGraph({
    this.date,
    this.day,
    this.trips,
    this.distance,
    this.operatedHours,
  });

  WeeklyTripsGraph.fromJson(Map<String, dynamic> json) {
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

class MonthlyTripsGraph {
  String? week;
  String? from;
  String? to;
  int? trips;
  String? distance;
  String? operatedHours;

  MonthlyTripsGraph({
    this.week,
    this.from,
    this.to,
    this.trips,
    this.distance,
    this.operatedHours,
  });

  MonthlyTripsGraph.fromJson(Map<String, dynamic> json) {
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
