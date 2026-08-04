class BaseURLConfig {
  //   static const String baseURL = 'http://192.168.1.68:8001';
  // static const String baseURL =
  // 'http://hero-trakmate.ap-south-1.elasticbeanstalk.com';
  // static const String baseURL = 'https://ev-backend.trakmatesolutions.com';

  static const String baseURL = "https://fleet-backend.trakmatesolutions.com";
  // static const String baseURL = 'http://localhost:8001';

  // login
  static const String loginApiURL = '$baseURL/api/signin';

  //CRUD API URLs
  static const String userApiURL = '$baseURL/api/user';

  static const String UpdateUserApiURL = '$baseURL/api/super/user';

  static const String groupApiURL = '$baseURL/api/groups';

  static const String commandsALLApiURL = '$baseURL/api/commands/ALL';

  static const String apiKeyApiUrl = '$baseURL/api/apikey';

  static const String devicesApiUrl = '$baseURL/api/device?';

  static const String devicesDeleteApiUrl = '$baseURL/api/device';

  static const String orgApiUrl = '$baseURL/api/super/org?';
  static const String orgDeleteApiUrl = '$baseURL/api/super/org';
  static const String canConfigOrgNameApiUrl =
      '$baseURL/api/super/orgCANTabMapping';
  static const String canTabNameApiUrl = '$baseURL/api/super/canTabNames';

  // dashboard all details
  static const String dashboardApiUrl = '$baseURL/api/dashboard/summary';

  static const String alertDashboardApiUrl = '$baseURL/api/dashboard/alerts';

  static const String alertGraphApiUrl = '$baseURL/api/dashboard/alerts/graph';

  static const String tripDashboardApiUrl = '$baseURL/api/dashboard/trips';

  static const String tripGraphApiUrl = '$baseURL/api/dashboard/trips/graph';

  static const String vehicleDashboardApiUrl =
      '$baseURL/api/dashboard/vehicles';
  //   static const String vehicleDashboardApiUrl =
  //       '$baseURL/api/v3/vehicle-summary';
  //   static const String alertDashboardApiUrl = '$baseURL/api/v3/alerts-summary';
  //   static const String tripDashboardApiUrl = '$baseURL/api/v3/trips-summary';

  //device full details
  static const String deviceDetailsApiUrl = '$baseURL/api/v3/devices';
  static const String devicesMapApiUrl = '$baseURL/api/v3/devices/map';
  static const String deviceOverviewApiUrl = '$baseURL/api/device/overview';
  static const String deviceDiagnosticApiUrl =
      '$baseURL/api/device/Diagnostics';
  static const String deviceCanApiUrl =
      '$baseURL/api/device/orgCanData/download';
  static const String deviceConfigurationApiUrl = '$baseURL/api/commands';
  static const String deviceAlertsApiUrl = '$baseURL/api/alerts/details';
  static const String deviceTripsApiUrl = '$baseURL/api/tripfulldetails';
  static const String deviceTripMapPointsApiUrl = '$baseURL/api/tripmappoints';
  static const String deviceTripMapApiUrl = '$baseURL/api/device/map';
  static const String deviceGraphApiUrl = '$baseURL/api/device/graphDetails';
  static const String deviceVehicleGraphApiUrl =
      '$baseURL/api/device/vehicleGraph';
  static const String deviceDistSpeedSocApiUrl =
      '$baseURL/api/v3/device/SpeedDistanceMap';

  // trips
  static const String tripsApiUrl = '$baseURL/api/trips/status';
  static const String tripsRoutePlayBackPerTripIDApiUrl =
      '$baseURL/api/trips/tripRoutePlayback/{tripId}';
  static const String downloadDetailedTripApiUrl =
      '$baseURL/api/v3/trips/tripRoutePlayback/{tripId}';

  // alerts
  static const String alertsApiUrl = '$baseURL/api/alerts';
  static const String alertApiUrl = '$baseURL/api/alerts';
  static const String alertCountApiUrl =
      '$baseURL/api/alerts/critical-overview';
  static const String reportsApiUrl = '$baseURL/api/v3/report';
  static const String vehicleReportApiUrl = '$baseURL/api/v3/reports/vehicle';
  static const String vehicleSummaryReportApiUrl =
      '$baseURL/api/v3/reports/vehicleSummary';
  static const String tripReportApiUrl = '$baseURL/api/v3/reports/trips';
  static const String alertReportApiUrl = '$baseURL/api/v3/reports/Alerts';

  static const String batteryReportApiUrl = '$baseURL/api/v3/reports/battery';
  static const String batterySummaryReportApiUrl =
      '$baseURL/api/v3/reports/batterysummary';
  static const String deviceDetailApiUrl = '$baseURL/api/device/deviceDetails';
}
