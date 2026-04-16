class IMEIGraphModel {
  String? imei;
  List<WeeklyTripsGraph>? weeklyTripsGraph;
  List<MonthlyTripsGraph>? monthlyTripsGraph;
  List<WeeklyAlertsGraph>? weeklyAlertsGraph;
  List<MonthlyAlertsGraph>? monthlyAlertsGraph;
  List<VehistatsGraph>? vehistatsGraph;

  IMEIGraphModel({
    this.imei,
    this.weeklyTripsGraph,
    this.monthlyTripsGraph,
    this.weeklyAlertsGraph,
    this.monthlyAlertsGraph,
    this.vehistatsGraph,
  });

  IMEIGraphModel.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    if (json['weeklyTripsGraph'] != null) {
      weeklyTripsGraph = <WeeklyTripsGraph>[];
      json['weeklyTripsGraph'].forEach((v) {
        weeklyTripsGraph!.add(new WeeklyTripsGraph.fromJson(v));
      });
    }
    if (json['monthlyTripsGraph'] != null) {
      monthlyTripsGraph = <MonthlyTripsGraph>[];
      json['monthlyTripsGraph'].forEach((v) {
        monthlyTripsGraph!.add(new MonthlyTripsGraph.fromJson(v));
      });
    }
    if (json['weeklyAlertsGraph'] != null) {
      weeklyAlertsGraph = <WeeklyAlertsGraph>[];
      json['weeklyAlertsGraph'].forEach((v) {
        weeklyAlertsGraph!.add(new WeeklyAlertsGraph.fromJson(v));
      });
    }
    if (json['monthlyAlertsGraph'] != null) {
      monthlyAlertsGraph = <MonthlyAlertsGraph>[];
      json['monthlyAlertsGraph'].forEach((v) {
        monthlyAlertsGraph!.add(new MonthlyAlertsGraph.fromJson(v));
      });
    }
    if (json['vehistatsGraph'] != null) {
      vehistatsGraph = <VehistatsGraph>[];
      json['vehistatsGraph'].forEach((v) {
        vehistatsGraph!.add(new VehistatsGraph.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imei'] = this.imei;
    if (this.weeklyTripsGraph != null) {
      data['weeklyTripsGraph'] =
          this.weeklyTripsGraph!.map((v) => v.toJson()).toList();
    }
    if (this.monthlyTripsGraph != null) {
      data['monthlyTripsGraph'] =
          this.monthlyTripsGraph!.map((v) => v.toJson()).toList();
    }
    if (this.weeklyAlertsGraph != null) {
      data['weeklyAlertsGraph'] =
          this.weeklyAlertsGraph!.map((v) => v.toJson()).toList();
    }
    if (this.monthlyAlertsGraph != null) {
      data['monthlyAlertsGraph'] =
          this.monthlyAlertsGraph!.map((v) => v.toJson()).toList();
    }
    if (this.vehistatsGraph != null) {
      data['vehistatsGraph'] =
          this.vehistatsGraph!.map((v) => v.toJson()).toList();
    }
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

class WeeklyAlertsGraph {
  String? date;
  String? day;
  int? critical;
  int? nonCritical;

  WeeklyAlertsGraph({this.date, this.day, this.critical, this.nonCritical});

  WeeklyAlertsGraph.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    day = json['day'];
    critical = json['Critical'];
    nonCritical = json['Non-critical'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['day'] = this.day;
    data['Critical'] = this.critical;
    data['Non-critical'] = this.nonCritical;
    return data;
  }
}

class MonthlyAlertsGraph {
  String? week;
  String? from;
  String? to;
  int? critical;
  int? nonCritical;

  MonthlyAlertsGraph({
    this.week,
    this.from,
    this.to,
    this.critical,
    this.nonCritical,
  });

  MonthlyAlertsGraph.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    from = json['from'];
    to = json['to'];
    critical = json['Critical'];
    nonCritical = json['Non-critical'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['week'] = this.week;
    data['from'] = this.from;
    data['to'] = this.to;
    data['Critical'] = this.critical;
    data['Non-critical'] = this.nonCritical;
    return data;
  }
}

class VehistatsGraph {
  String? time;
  int? moving;
  int? idle;
  int? halted;
  int? stopped;

  VehistatsGraph({
    this.time,
    this.moving,
    this.idle,
    this.halted,
    this.stopped,
  });

  VehistatsGraph.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    moving = json['Moving'];
    idle = json['Idle'];
    halted = json['Halted'];
    stopped = json['Stopped'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['Moving'] = this.moving;
    data['Idle'] = this.idle;
    data['Halted'] = this.halted;
    data['Stopped'] = this.stopped;
    return data;
  }
}
