class BaseURLConfig {
  static const String baseURL = 'https://ev-backend.trakmatesolutions.com';

  // login
  static const String loginApiURL = '$baseURL/api/signin';

  // user CRUD
  static const String userApiURL = '$baseURL/api/user';

  // group CRUD
  static const String groupApiURL = '$baseURL/api/groups';

  // Commands CRUD
  static const String commandsALLApiURL = '$baseURL/api/commands/ALL';

  //api key CRUD
  static const String apiKeyApiUrl = '$baseURL/api/apikey';

  // devices/vehicles CRUD
  static const String devicesApiUrl = '$baseURL/api/apikey';

  // trips
  static const String tripsApiUrl = '$baseURL/api/trips';

  // dasboard all data
  static const String dashboardApiUrl = '$baseURL/api/dashboard/evAllData';

  // alerts
  static const String alertsApiUrl = '$baseURL/api/dashboard/evAllDatalistData';

  // trip data
  static const String tripApiUrl =
      '$baseURL/api/trips?currentIndex=0&sizePerPage=10';

  static const String vehicleStatusApiUrl = '$baseURL/api/device';

  static const String vehicleCommand = '$baseURL/api/commands';

  static const String Groups = '$baseURL/api/groups/all';

  static const String devicesStatusUrl = '$baseURL/api/device/dashboardMap?';

  // static const String devicesStatusUrl = '$baseURL /api/dashboard/evAllDatalistData';
}
