import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:svg_flutter/svg_flutter.dart';
import '../../models/deviceDetailsModel.dart';
import '../../models/devicesModel.dart';
import '../../models/imeiCommandsModel.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceConfigurationAPIService.dart';
import '../../services/generalAPIServices.dart/deviceDetailsAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../components/hoverWrapper.dart';
import '../components/smallHoverCard.dart';

class DeviceConfigInfoScreen extends StatefulWidget {
  final DeviceEntity device;

  const DeviceConfigInfoScreen({super.key, required this.device});

  @override
  State<DeviceConfigInfoScreen> createState() => _DeviceConfigInfoScreenState();
}

class _DeviceConfigInfoScreenState extends State<DeviceConfigInfoScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  final TextEditingController _customCommandController =
      TextEditingController();
  String? _selectedCommand;

  int currentPage = 1;
  int rowsPerPage = 15;
  int totalPages = 1;

  final List<Map<String, String>> _defaultCommandButtons = [
    {'label': 'SHOW CONFIG', 'cmd': 'SHOW CONFIG'},
    {'label': 'SHOW IOSTATUS', 'cmd': 'SHOW IOSTATUS'},
    {'label': 'START OTA', 'cmd': 'START OTA'},

    // {'label': 'MOBILIZE', 'cmd': 'SET IMMOBILIZE DISABLE'},
    // {'label': 'IMMOBILIZE', 'cmd': 'SET IMMOBILIZE ENABLE'},
    // {'label': 'CMOS ENABLE', 'cmd': 'BMS CHG ENABLE'},
    // {'label': 'CMOS DISABLE', 'cmd': 'BMS CHG DISABLE'},
    // {'label': 'DMOS ENABLE', 'cmd': 'BMS DSCHG ENABLE'},
    // {'label': 'DMOS DISABLE', 'cmd': 'BMS DSCHG DISABLE'},
    // {'label': 'BUZZER ENABLE', 'cmd': 'BMS BUZZER ON'},
    // {'label': 'BUZZER DISABLE', 'cmd': 'BMS BUZZER OFF'},
  ];
  DeviceDetailsModel? deviceDetailsModel;
  final DeviceDetailsApiService _deviceDetailsApiService =
      DeviceDetailsApiService();
  final List<Map<String, String>> _customCommandOptions = [
    {'label': 'MOBILIZE', 'cmd': 'SET IMMOBILIZE DISABLE'},
    {'label': 'IMMOBILIZE', 'cmd': 'SET IMMOBILIZE ENABLE'},
    {'label': 'CMOS ENABLE', 'cmd': 'BMS CHG ENABLE'},
    {'label': 'CMOS DISABLE', 'cmd': 'BMS CHG DISABLE'},
    {'label': 'DMOS ENABLE', 'cmd': 'BMS DSCHG ENABLE'},
    {'label': 'DMOS DISABLE', 'cmd': 'BMS DSCHG DISABLE'},
    {'label': 'BUZZER ENABLE', 'cmd': 'BMS BUZZER ON'},
    {'label': 'BUZZER DISABLE', 'cmd': 'BMS BUZZER OFF'},
  ];

  final List<Map<String, dynamic>> toggleGroups = [
    {
      "label": "IMMOBILIZE",
      "enable": "IMMOBILIZE",
      "disable": "MOBILIZE",
      "color": tGreen,
      "icon": "icons/immobilize.svg",
    },
    {
      "label": "CMOS",
      "enable": "CMOS ENABLE",
      "disable": "CMOS DISABLE",
      "color": Colors.tealAccent,
      "icon": "icons/chargingMosfet.svg",
    },
    {
      "label": "DMOS",
      "enable": "DMOS ENABLE",
      "disable": "DMOS DISABLE",
      "color": Colors.purpleAccent,
      "icon": "icons/battery.svg",
    },
    {
      "label": "BUZZER",
      "enable": "BUZZER ENABLE",
      "disable": "BUZZER DISABLE",
      // "color": tBlue1,
      "color": tOrange,
      "icon": "icons/buzzer.svg",
    },
  ];

  late final Map<String, String> commandMap;

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(dateStr).toLocal(); // important
      return DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  final IMEICommandsApiService _commandsApi = IMEICommandsApiService();

  List<Entities> _commandLogsApi = [];
  bool isLoading = false;
  int totalCount = 0;

  Future<void> fetchCommandLogs() async {
    setState(() => isLoading = true);

    try {
      final result = await _commandsApi.fetchCommands(
        imei: widget.device.imei ?? '',
        page: currentPage,
        sizePerPage: rowsPerPage,
        currentIndex: (currentPage - 1) * rowsPerPage,
      );

      setState(() {
        final data = result.entities ?? [];

        _commandLogsApi = data.take(rowsPerPage).toList();
        // _commandLogsApi = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      // isLoading = false;
      setState(() => isLoading = false);
      debugPrint('Error fetching command logs: $e');
    }
  }

  Future<void> _sendCommand(String command) async {
    if (command.isEmpty) return;

    try {
      setState(() => isLoading = true);

      await _commandsApi.sendCommand(
        imei: widget.device.imei ?? '',
        command: command,
      );

      _customCommandController.clear();
      _selectedCommand = null;

      currentPage = 1;
      // await fetchCommandLogs();
      for (int i = 0; i < 3; i++) {
        await fetchCommandLogs();
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } catch (e) {
      debugPrint('Error sending command: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send command'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchDeviceDetails() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await _deviceDetailsApiService.fetchDeviceDetails(
        deviceId: widget.device.imei!,
      );

      if (!mounted) return;

      setState(() {
        deviceDetailsModel = result;
      });
    } catch (e) {
      debugPrint("Device Details API Error: $e");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    commandMap = {
      for (var item in _customCommandOptions) item['label']!: item['cmd']!,
    };
    fetchCommandLogs();
    fetchDeviceDetails();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    final device = widget.device;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Device Info",
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                SizedBox(height: 5),
                FutureBuilder<String>(
                  // future: getAddressFromLocationStringWeb(
                  //   device.location ?? '',
                  // ),
                  future: getAddressFromLocationStringWeb(
                    deviceDetailsModel?.lat != null &&
                            deviceDetailsModel?.long != null
                        ? '${deviceDetailsModel!.lat},${deviceDetailsModel!.long}'
                        : "",
                  ),
                  builder: (context, snapshot) {
                    final address =
                        snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData
                            ? snapshot.data!
                            : 'Fetching location...';

                    return buildDeviceCard(
                      isDark: isDark,
                      // imei: device.imei ?? '',
                      imei: deviceDetailsModel?.imei ?? '',
                      // vehicleNumber: device.vehicleNumber ?? '',
                      vehicleNumber: deviceDetailsModel?.vehicleNumber ?? '',
                      // status: device.status ?? '',
                      status: deviceDetailsModel?.status ?? '',
                      fuel: device.soc ?? '',
                      odo: device.odometer ?? '',
                      trips: (device.totalTrips ?? '').toString(),
                      alerts: (device.totalAlerts ?? '').toString(),
                      location: address,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 10,
                  children:
                      toggleGroups.map((item) {
                        final enableCmd = commandMap[item['enable']];
                        final disableCmd = commandMap[item['disable']];

                        final isEnabled = _selectedCommand == enableCmd;

                        return SizedBox(
                          width: 230,
                          child: ToggleCard(
                            label: item['label'],
                            icon: item['icon'],
                            color: item['color'],
                            isEnabled: isEnabled,
                            isDark: isDark,
                            onToggle: (val) async {
                              final command = val ? enableCmd! : disableCmd!;

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Confirm Action"),
                                    content: Text(
                                      "Are you sure you want to send this command?",
                                      style: GoogleFonts.urbanist(
                                        color: isDark ? tWhite : tBlack,
                                      ),
                                    ),
                                    backgroundColor: isDark ? tBlack : tWhite,
                                    shadowColor: tWhite,
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.urbanist(
                                            color: isDark ? tWhite : tBlack,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: Text(
                                          "Ok",
                                          style: GoogleFonts.urbanist(
                                            color: isDark ? tWhite : tBlack,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                setState(() {
                                  _selectedCommand = command;
                                });

                                _sendCommand(command);
                              }
                            },
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Default Commands",
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tGreen8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        "Send",
                        style: GoogleFonts.urbanist(
                          color: tBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        final command =
                            _customCommandController.text.isNotEmpty
                                ? _customCommandController.text
                                : (_selectedCommand ?? '');
                        _sendCommand(command);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      _defaultCommandButtons.map((cmd) {
                        final isSelected = _selectedCommand == cmd['cmd'];

                        Color baseColor;
                        switch (cmd['label']) {
                          case 'SHOW CONFIG':
                            baseColor = tBlue;
                            break;
                          case 'SHOW IOSTATUS':
                            baseColor = tPink2;
                            break;
                          case 'START OTA':
                            baseColor = tBlueSky;
                            break;
                          case 'MOBILIZE':
                            baseColor = tGreen;
                            break;
                          case 'IMMOBILIZE':
                            baseColor = tRedDark;
                            break;
                          case 'CMOS ENABLE':
                            baseColor = Colors.tealAccent;
                            break;
                          case 'CMOS DISABLE':
                            baseColor = tBlue1;
                            break;
                          case 'DMOS ENABLE':
                            baseColor = Colors.purpleAccent;
                            break;
                          case 'DMOS DISABLE':
                            baseColor = tOrange1;
                            break;
                          case 'BUZZER ENABLE':
                            baseColor = tGreen;
                            break;
                          case 'BUZZER DISABLE':
                            baseColor = tGreenDark;
                            break;
                          default:
                            baseColor = tGrey;
                        }

                        return TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                                isSelected
                                    ? baseColor
                                    : baseColor.withOpacity(0.15),
                            foregroundColor: isSelected ? tWhite : baseColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _selectedCommand = cmd['cmd']);
                          },
                          child: Text(
                            cmd['label'] ?? '',
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 20),

                Text(
                  "Custom Commands",
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: TextField(
                          controller: _customCommandController,
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: isDark ? tWhite : tBlack,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter command...",
                            hintStyle: GoogleFonts.urbanist(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.5)
                                      : tBlack.withOpacity(0.5),
                              fontSize: 13,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.4)
                                        : tBlack.withOpacity(0.4),
                                width: 1,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: BorderSide(color: tBlue, width: 1.2),
                            ),

                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: const BorderSide(
                                color: tRed,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    SizedBox(
                      height: 35,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tGreen8,
                          shape: RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final command = _customCommandController.text.trim();

                          if (command.isEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  backgroundColor:
                                      Colors.transparent, // important
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Container(
                                    width: 250,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? tBlack : tWhite,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color:
                                            isDark
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Text(
                                          "Warning",
                                          style: GoogleFonts.urbanist(
                                            color: isDark ? tWhite : tBlack,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        // Content
                                        Text(
                                          "Please enter a command",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.urbanist(
                                            color: isDark ? tWhite : tBlack,
                                            fontSize: 14,
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // Button
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text(
                                              "OK",
                                              style: GoogleFonts.urbanist(
                                                color: tGreen8,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                            return;
                          }

                          _sendCommand(command);
                        },

                        child: Text(
                          "Send",
                          style: GoogleFonts.urbanist(
                            color: tBlack,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Wrap(
                //   spacing: 15,
                //   runSpacing: 15,
                //   children:
                //       _customCommandOptions.map((cmd) {
                //         final isSelected = _selectedCommand == cmd['cmd'];

                //         Color baseColor;
                //         switch (cmd['label']) {
                //           case 'MOBILIZE':
                //             baseColor = tGreen;
                //             break;
                //           case 'IMMOBILIZE':
                //             baseColor = tRedDark;
                //             break;
                //           case 'CMOS ENABLE':
                //             baseColor = Colors.tealAccent;
                //             break;
                //           case 'CMOS DISABLE':
                //             baseColor = tBlue1;
                //             break;
                //           case 'DMOS ENABLE':
                //             baseColor = Colors.purpleAccent;
                //             break;
                //           case 'DMOS DISABLE':
                //             baseColor = tOrange1;
                //             break;
                //           case 'BUZZER ENABLE':
                //             baseColor = tGreen;
                //             break;
                //           case 'BUZZER DISABLE':
                //             baseColor = tGreenDark;
                //             break;
                //           default:
                //             baseColor = tGrey;
                //         }

                //         return TextButton(
                //           style: TextButton.styleFrom(
                //             backgroundColor:
                //                 isSelected
                //                     ? baseColor
                //                     : baseColor.withOpacity(0.15),
                //             foregroundColor: isSelected ? tWhite : baseColor,
                //             padding: const EdgeInsets.symmetric(
                //               horizontal: 16,
                //               vertical: 10,
                //             ),
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(5),
                //             ),
                //           ),
                //           onPressed: () {
                //             setState(() => _selectedCommand = cmd['cmd']);
                //           },
                //           child: Text(
                //             cmd['label'] ?? '',
                //             style: GoogleFonts.urbanist(
                //               fontSize: 13,
                //               fontWeight: FontWeight.w500,
                //             ),
                //           ),
                //         );
                //       }).toList(),
                // ),

                // Container(
                //   // width: 170,
                //   decoration: BoxDecoration(
                //     color: tGreen2,
                //     borderRadius: BorderRadius.circular(35),
                //   ),
                //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 45,
                //         height: 45,
                //         decoration: BoxDecoration(
                //           color: tBlack,
                //           shape: BoxShape.circle,
                //         ),
                //         child: Center(
                //           child: SvgPicture.asset(
                //             'icons/battery.svg',
                //             width: 25,
                //             height: 25,
                //             color: tGreen2,
                //           ),
                //         ),
                //       ),
                //       SizedBox(width: 5),
                //       Text(
                //         'MOBILIZE OFF',
                //         style: GoogleFonts.urbanist(
                //           fontSize: 14,
                //           fontWeight: FontWeight.bold,
                //           color: tBlack,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // SizedBox(height: 15),
                // Wrap(
                //   spacing: 12,
                //   runSpacing: 12,
                //   children:
                //       toggleGroups.map((item) {
                //         final enableLabel = item['enable'];
                //         final disableLabel = item['disable'];

                //         final enableCmd = commandMap[enableLabel];
                //         final disableCmd = commandMap[disableLabel];

                //         final isEnabled = _selectedCommand == enableCmd;

                //         return ToggleCommandCard(
                //           label: item['label'],
                //           isEnabled: isEnabled,
                //           activeColor: item['color'],
                //           iconPath: item['icon'],
                //           isDark: isDark,
                //           onToggle: (val) {
                //             setState(() {
                //               _selectedCommand = val ? enableCmd! : disableCmd!;
                //             });

                //             // 🔥 optional auto send
                //             _sendCommand(_selectedCommand!);
                //           },
                //         );
                //       }).toList(),
                // ),
                // SizedBox(height: 15),

                // Wrap(
                //   spacing: 15,
                //   runSpacing: 15,
                //   children:
                //       toggleGroups.map((item) {
                //         final enableCmd = commandMap[item['enable']];
                //         final disableCmd = commandMap[item['disable']];

                //         final isEnabled = _selectedCommand == enableCmd;

                //         return GestureDetector(
                //           onTap: () {
                //             setState(() {
                //               _selectedCommand =
                //                   isEnabled ? disableCmd! : enableCmd!;
                //             });
                //           },
                //           child: Container(
                //             width: 240,
                //             padding: const EdgeInsets.all(12),
                //             decoration: BoxDecoration(
                //               borderRadius: BorderRadius.circular(12),
                //               color: isDark ? Colors.black12 : Colors.white,
                //               border: Border.all(
                //                 color:
                //                     isEnabled
                //                         ? item['color']
                //                         : (isDark
                //                             ? Colors.white24
                //                             : Colors.black26),
                //               ),
                //             ),
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 // 🔹 TOP LABEL (CMOS / DMOS / etc)
                //                 Text(
                //                   item['label'],
                //                   style: GoogleFonts.urbanist(
                //                     fontSize: 13,
                //                     fontWeight: FontWeight.w600,
                //                     color: isDark ? tWhite : tBlack,
                //                   ),
                //                 ),

                //                 const SizedBox(height: 12),

                //                 Container(
                //                   height: 36,
                //                   padding: const EdgeInsets.symmetric(
                //                     horizontal: 4,
                //                   ),
                //                   decoration: BoxDecoration(
                //                     borderRadius: BorderRadius.circular(20),
                //                     color: Colors.grey.withOpacity(0.2),
                //                   ),
                //                   child: Stack(
                //                     alignment: Alignment.center,
                //                     children: [
                //                       // 🔹 TEXT (LEFT & RIGHT LABELS)
                //                       Row(
                //                         mainAxisAlignment:
                //                             MainAxisAlignment.spaceBetween,
                //                         children: [
                //                           Expanded(
                //                             child: Center(
                //                               child: Text(
                //                                 item['disable'],
                //                                 style: GoogleFonts.urbanist(
                //                                   fontSize: 11,
                //                                   fontWeight: FontWeight.w500,
                //                                   color:
                //                                       !isEnabled
                //                                           ? tBlack
                //                                           : Colors.black45,
                //                                 ),
                //                               ),
                //                             ),
                //                           ),
                //                           Expanded(
                //                             child: Center(
                //                               child: Text(
                //                                 item['enable'],
                //                                 style: GoogleFonts.urbanist(
                //                                   fontSize: 11,
                //                                   fontWeight: FontWeight.w500,
                //                                   color:
                //                                       isEnabled
                //                                           ? tBlack
                //                                           : Colors.black45,
                //                                 ),
                //                               ),
                //                             ),
                //                           ),
                //                         ],
                //                       ),

                //                       AnimatedAlign(
                //                         duration: const Duration(
                //                           milliseconds: 250,
                //                         ),
                //                         alignment:
                //                             isEnabled
                //                                 ? Alignment.centerRight
                //                                 : Alignment.centerLeft,
                //                         child: Container(
                //                           width: 120,
                //                           height: 30,
                //                           // margin: const EdgeInsets.all(3),
                //                           decoration: BoxDecoration(
                //                             borderRadius: BorderRadius.circular(
                //                               20,
                //                             ),
                //                             color: item['color'],
                //                           ),
                //                           child: Center(
                //                             child: Text(
                //                               isEnabled
                //                                   ? item['enable']
                //                                   : item['disable'],
                //                               style: GoogleFonts.urbanist(
                //                                 fontSize: 11,
                //                                 fontWeight: FontWeight.w600,
                //                                 color: tWhite,
                //                               ),
                //                             ),
                //                           ),
                //                         ),
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         );
                //       }).toList(),
                // ),
              ],
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(flex: 6, child: _buildCommandLogTable(isDark)),
      ],
    );
  }

  Widget _buildCommandLogTable(bool isDark) {
    int totalPages = (totalCount / rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        Color getTypeColor(String type) {
          final value = type.toLowerCase();

          if (value.contains('sent')) {
            return tBlue;
          } else if (value.contains('received')) {
            return tGreen;
          } else if (value.contains('failed') || value.contains('error')) {
            return tRed;
          } else {
            return tGrey;
          }
        }

        return Container(
          width: maxWidth,
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable Table Area
              Expanded(
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 6,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: maxWidth),
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark
                                  ? tBlue.withOpacity(0.15)
                                  : tBlue.withOpacity(0.05),
                            ),
                            headingTextStyle: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w700,
                              color: isDark ? tWhite : tBlack,
                              fontSize: 13,
                            ),
                            dataTextStyle: GoogleFonts.urbanist(
                              color: isDark ? tWhite : tBlack,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                            columnSpacing: 30,
                            border: TableBorder.all(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.1)
                                      : tBlack.withOpacity(0.1),
                              width: 0.4,
                            ),
                            dividerThickness: 0.01,
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Sent Data')),
                              DataColumn(label: Text('Received Data')),
                              DataColumn(label: Text('User')),
                            ],
                            rows:
                                _commandLogsApi.map((cmd) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(formatDate(cmd.date))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getTypeColor(
                                              cmd.type ?? '',
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            cmd.type ?? '',
                                            style: GoogleFonts.urbanist(
                                              color: getTypeColor(
                                                cmd.type ?? '',
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(cmd.commandSent ?? '')),
                                      DataCell(Text(cmd.dataReceived ?? '')),
                                      DataCell(Text(cmd.userId ?? '')),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Optional pagination (if needed in future)
              if (totalPages > 1) _buildPaginationControls(isDark, totalPages),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(bool isDark, int totalPages) {
    const int visiblePageCount = 5;

    // Calculate visible window
    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// ◀ PREVIOUS
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: currentPage > 1 ? (isDark ? tWhite : tBlack) : Colors.grey,
            ),
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() => currentPage--);
                      fetchCommandLogs();
                    }
                    : null,

            tooltip: "Previous page",
          ),

          /// 🔢 Page Number Links
          Wrap(
            spacing: 6,
            children: List.generate((endPage - startPage + 1), (i) {
              final pageNum = startPage + i;
              final isSelected = pageNum == currentPage;
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  setState(() => currentPage = pageNum);
                  fetchCommandLogs();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? tBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isSelected
                              ? tBlue
                              : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                  child: Text(
                    '$pageNum',
                    style: GoogleFonts.urbanist(
                      color:
                          isSelected
                              ? tWhite
                              : (isDark
                                  ? tWhite.withOpacity(0.8)
                                  : tBlack.withOpacity(0.8)),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),

          /// NEXT
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color:
                  currentPage < totalPages
                      ? (isDark ? tWhite : tBlack)
                      : Colors.grey,
            ),
            onPressed:
                currentPage < totalPages
                    ? () {
                      setState(() => currentPage++);
                      fetchCommandLogs();
                    }
                    : null,
            tooltip: "Next page",
          ),

          const SizedBox(width: 16),

          /// Go To Page Box
          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: controller,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: isDark ? tWhite : tBlack,
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Go to',
                hintStyle: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        isDark
                            ? tWhite.withOpacity(0.5)
                            : tBlack.withOpacity(0.5),
                    width: 0.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: tBlue, width: 1),
                ),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null &&
                    page >= 1 &&
                    page <= totalPages &&
                    mounted) {
                  setState(() => currentPage = page);
                  fetchCommandLogs();
                }
              },
            ),
          ),

          const SizedBox(width: 14),

          /// 📘 Page Info
          Text(
            'Page $currentPage of $totalPages',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDeviceCard({
    required bool isDark,
    required String vehicleNumber,
    required String status,
    required String imei,
    required String fuel,
    required String odo,
    required String trips,
    required String alerts,
    required String location,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'moving':
        statusColor = tGreen;
        break;
      case 'idle':
        statusColor = tOrange1;
        break;
      case 'stopped':
        statusColor = tRed;
        break;
      case 'disconnected':
        statusColor = tGrey;
        break;
      case 'discharging':
        statusColor = tGreen;
        break;
      case 'charging':
        // statusColor = Colors.teal;
        statusColor = tBlue;
        break;
      case 'non coverage':
        statusColor = const Color(0xFF9C27B0);
        break;
      default:
        statusColor = tBlack;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(
          color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
          width: 0.4,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMEI + Vehicle + Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns status on top
            children: [
              /// IMEI + Vehicle box (fixed width)
              Container(
                width: 250, // fixed width (adjust as you like)
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        // color: statusColor,
                        gradient: SweepGradient(
                          colors: [statusColor, statusColor.withOpacity(0.6)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                      ),
                      child: Text(
                        imei,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          // color: isDark ? tBlack : tWhite,
                          color: tWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        vehicleNumber,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),

              /// 🔹 Status container (top-aligned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // color: statusColor,
                  gradient: SweepGradient(
                    colors: [statusColor, statusColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    // color: isDark ? tBlack : tWhite,
                    color: tWhite,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(
            color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
            thickness: 0.3,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                'icons/geofence.svg',
                width: 16,
                height: 16,
                color: tGreen,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ToggleCommandCard extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final Color activeColor;
  final String iconPath;
  final bool isDark;
  final Function(bool) onToggle;

  const ToggleCommandCard({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.activeColor,
    required this.iconPath,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 SLIDING CIRCLE
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment:
                  isEnabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Row(
                children: [
                  if (!isEnabled) _buildCircle(),

                  SizedBox(width: 5),

                  Text(
                    "$label ${isEnabled ? "ON" : "OFF"}",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),

                  SizedBox(width: 5),

                  if (isEnabled) _buildCircle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle() {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(color: tBlack, shape: BoxShape.circle),
      child: Center(
        child: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          color: activeColor,
        ),
      ),
    );
  }
}

class ToggleCard extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final bool isEnabled;
  final bool isDark;
  final Function(bool) onToggle;

  const ToggleCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Widget card(bool hover) {
      return GestureDetector(
        onTap: () => onToggle(!isEnabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 85,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,

            // 🔥 HOVER BORDER
            border: Border.all(
              width: hover ? 1.5 : 0,
              color:
                  hover
                      ? color.withOpacity(0.7)
                      : (isEnabled
                          ? color.withOpacity(0.7)
                          : Colors.transparent),
            ),

            borderRadius: BorderRadius.circular(8),

            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 2,
                color:
                    isDark ? tWhite.withOpacity(0.12) : tBlack.withOpacity(0.1),
              ),
            ],
          ),

          child: Row(
            children: [
              // 🔹 ICON
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tBlue1.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 25,
                    height: 25,
                    color: tBlue1,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tBlue1,
                      ),
                    ),

                    const SizedBox(height: 6),
                    buildWideToggle(isEnabled, onToggle, isDark),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       isEnabled ? "ON" : "OFF",
                    //       style: GoogleFonts.urbanist(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //         color: isEnabled ? color : tRed,
                    //       ),
                    //     ),

                    // Switch(
                    //   value: isEnabled,
                    //   activeColor: tGreen,
                    //   onChanged: onToggle,
                    //   inactiveThumbColor: tRed,
                    //   inactiveTrackColor: tRed.withOpacity(0.1),
                    //   trackOutlineColor: MaterialStateProperty.resolveWith((
                    //     states,
                    //   ) {
                    //     if (states.contains(MaterialState.selected)) {
                    //       return tGreen;
                    //     }
                    //     return tRed;
                    //   }),
                    //   trackOutlineWidth: MaterialStateProperty.all(1),
                    // ),
                    // ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HoverWrapper(builder: (hover) => card(hover));
  }
}

Widget buildWideToggle(bool isEnabled, Function(bool) onToggle, bool isDark) {
  return GestureDetector(
    onTap: () => onToggle(!isEnabled),
    child: Container(
      width: 110,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? tBlack : tWhite,
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    "OFF",
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tRed,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "ON",
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),

          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 55,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // color: isEnabled ? tGreen : tRed,
                color:
                    isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  isEnabled ? "ON" : "OFF",
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? tGreen : tRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
