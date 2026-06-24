import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/devicesModel.dart';

// void openDeviceOverview(BuildContext context, DeviceEntity device) {
//   context.pushNamed(
//     'Overview',
//     pathParameters: {'imei': device.imei ?? ''},
//     extra: device,
//   );
// }

// void openDeviceDiagnostics(BuildContext context, DeviceEntity device) {
//   context.pushNamed(
//     'deviceGoLive',
//     pathParameters: {'imei': device.imei ?? ''},
//     extra: device,
//   );
// }

// void openDeviceConfiguration(BuildContext context, DeviceEntity device) {
//   context.pushNamed(
//     'deviceControl',
//     pathParameters: {'imei': device.imei ?? ''},
//     extra: device,
//   );
// }

void openDeviceOverview(BuildContext context, DeviceEntity device) {
  context.go('/home/devices/${device.imei}/overview', extra: device);
}

void openDeviceDiagnostics(BuildContext context, DeviceEntity device) {
  context.go('/home/devices/${device.imei}/goLive', extra: device);
}

void openDeviceInformation(BuildContext context, DeviceEntity device) {
  context.go('/home/devices/${device.imei}/information', extra: device);
}

void openDeviceConfiguration(BuildContext context, DeviceEntity device) {
  context.go('/home/devices/${device.imei}/deviceControl', extra: device);
}
