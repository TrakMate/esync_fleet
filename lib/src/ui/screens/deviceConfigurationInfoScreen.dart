import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:svg_flutter/svg_flutter.dart';
import '../../models/deviceDetailsModel.dart';
import '../../models/devicesModel.dart';
import '../../models/imeiCommandsModel.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/generalAPIServices.dart/deviceAPIServices/deviceConfigurationAPIService.dart';
import '../../services/generalAPIServices.dart/deviceDetailsAPIService.dart';
import '../../services/getAddressService.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../components/hoverWrapper.dart';
import '../components/smallHoverCard.dart';
import '../widgets/reports/custom_Toast.dart';

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
  List<String> commandUsed = [];

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
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final result = await _commandsApi.fetchCommands(
        imei: widget.device.imei ?? '',
        page: currentPage,
        sizePerPage: rowsPerPage,
        currentIndex: (currentPage - 1) * rowsPerPage,
      );
      if (!mounted) return;
      final data = result.entities ?? [];

      setState(() {
        _commandLogsApi = data.take(rowsPerPage).toList();
        // _commandLogsApi = result.entities ?? [];
        totalCount = result.totalCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      // isLoading = false;
      setState(() => {isLoading = false});
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

  void _saveCommand(String command) {
    if (command.isNotEmpty && !commandUsed.contains(command)) {
      setState(() {
        commandUsed.insert(0, command); // latest first
      });
    }
  }

  void _showDefaultCommandDialog(BuildContext context, String selectedCommand) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final TextEditingController dialogController = TextEditingController(
      text: selectedCommand,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,

          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            decoration: BoxDecoration(
              color: isDark ? tBlack : tWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? Colors.white.withOpacity(0.7) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Confirm Action",
                  style: GoogleFonts.urbanist(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to send this command?",
                  style: GoogleFonts.urbanist(
                    fontSize: 16,

                    color: isDark ? tWhite : tBlack,
                  ),
                ),

                const SizedBox(height: 15),

                // TextField(
                //   controller: dialogController,
                //   readOnly: true,
                //   enableInteractiveSelection: false,
                //   showCursor: false,
                //   style: GoogleFonts.urbanist(
                //     fontSize: 14,
                //     color: isDark ? tWhite : tBlack,
                //     fontWeight: FontWeight.w500,
                //   ),
                //   decoration: InputDecoration(
                //     hintText: "Command",
                //     filled: true,
                //     fillColor:
                //         isDark
                //             ? Colors.white.withOpacity(0.05)
                //             : Colors.black.withOpacity(0.03),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     contentPadding: const EdgeInsets.symmetric(
                //       horizontal: 12,
                //       vertical: 12,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",

                        style: GoogleFonts.urbanist(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.6)
                                  : tBlack.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tGreen8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final command = dialogController.text.trim();

                        if (command.isNotEmpty) {
                          _sendCommand(command);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        "Send",
                        style: GoogleFonts.urbanist(
                          color: tWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool showSuggestions = false;

  void _showCustomCommandDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController dialogController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            decoration: BoxDecoration(
              color: isDark ? tBlack : tWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? Colors.white.withOpacity(0.7) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Custom Command",
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),

                const SizedBox(height: 15),

                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (!showSuggestions) {
                      return const Iterable<String>.empty();
                    }

                    if (textEditingValue.text.isEmpty) {
                      return commandUsed;
                    }

                    return commandUsed.where(
                      (cmd) => cmd.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },

                  onSelected: (String selection) {},

                  fieldViewBuilder: (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    dialogController.text = textEditingController.text;

                    textEditingController.addListener(() {
                      dialogController.value = textEditingController.value;
                    });
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onTap: () {
                        setState(() {
                          showSuggestions = true;
                        });
                      },
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      cursorColor: isDark ? tWhite : tBlack,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: isDark ? tWhite : tBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type command...",
                        hintStyle: GoogleFonts.urbanist(
                          fontSize: 14,
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.5)
                                  : tBlack.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.2)
                                    : tBlack.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.6)
                                    : tBlack.withOpacity(0.6),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (value) {
                        final command = value.trim();

                        if (command.isNotEmpty) {
                          _saveCommand(command);
                          _sendCommand(command);
                          Navigator.pop(context);
                        }
                      },
                    );
                  },

                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(10),
                        color: isDark ? tBlack : tWhite,
                        child: Container(
                          // width: MediaQuery.of(context).size.width * 0.35,
                          margin: const EdgeInsets.only(top: 6),
                          width: 360,
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.25)
                                      : tBlack.withOpacity(0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);

                              return ListTile(
                                dense: true,
                                title: Text(
                                  option,
                                  style: GoogleFonts.urbanist(
                                    color: isDark ? tWhite : tBlack,
                                  ),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Builder(
                  builder: (context) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.urbanist(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.6)
                                      : tBlack.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tGreen8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final command = dialogController.text.trim();

                            if (command.isEmpty) {
                              CustomToast.show(
                                context: context,
                                message: 'Please enter a command',
                                type: ToastType.error,
                              );
                              return;
                            }

                            _saveCommand(command);
                            _sendCommand(command);
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Send",
                            style: GoogleFonts.urbanist(
                              color: tWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
      mobile: _buildMobileLayout(isDark),
      tablet: _buildTabletLayout(isDark),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final device = widget.device;

    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Device Info",
                    style: GoogleFonts.urbanist(
                      fontSize: isMobile ? 13 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  SizedBox(height: 5),
                  FutureBuilder<String>(
                    future: getAddressFromLocationStringWeb(
                      deviceDetailsModel?.lat != null &&
                              deviceDetailsModel?.long != null
                          ? '${deviceDetailsModel!.lat},${deviceDetailsModel!.long}'
                          : "",
                    ),
                    builder: (context, snapshot) {
                      final displayStatus =
                          mode == 'EV Fleet'
                              ? (deviceDetailsModel?.status ??
                                  device.status ??
                                  '') // Use regular status for EV
                              : (deviceDetailsModel?.lstatus ??
                                  device.status ??
                                  '');
                      return buildDeviceCard(
                        isDark: isDark,
                        imei: deviceDetailsModel?.imei ?? device.imei ?? '',
                        vehicleNumber: deviceDetailsModel?.vehicleNumber ?? '',
                        status: displayStatus,
                        fuel: device.soc?.toString() ?? '',
                        odo: device.odometer?.toString() ?? '',
                        trips: (device.totalTrips ?? '').toString(),
                        alerts: (device.totalAlerts ?? '').toString(),
                        location:
                            (deviceDetailsModel?.address ?? '').toString(),
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
                            width: (MediaQuery.of(context).size.width / 2) - 25,
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
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: isDark ? tBlack : tWhite,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDark
                                                    ? Colors.white.withOpacity(
                                                      0.7,
                                                    )
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Confirm Action",
                                              style: GoogleFonts.urbanist(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? tWhite : tBlack,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            /// 🔹 Content
                                            Text(
                                              "Are you sure you want to send this command?",
                                              style: GoogleFonts.urbanist(
                                                fontSize: 16,
                                                color: isDark ? tWhite : tBlack,
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            /// 🔹 Actions
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text(
                                                    "Cancel",
                                                    style: GoogleFonts.urbanist(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          isDark
                                                              ? tWhite
                                                                  .withOpacity(
                                                                    0.7,
                                                                  )
                                                              : tBlack
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: tGreen8,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text(
                                                    "Ok",
                                                    style: GoogleFonts.urbanist(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          tWhite, // 🔥 keep white always
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                      // ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: tBlue,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 15,
                      //       vertical: 8,
                      //     ),
                      //   ),
                      //   child: Text(
                      //     "Send",
                      //     style: GoogleFonts.urbanist(
                      //       color: tWhite,
                      //       fontSize: 13,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      //   onPressed: () {
                      //     final command =
                      //         _customCommandController.text.isNotEmpty
                      //             ? _customCommandController.text
                      //             : (_selectedCommand ?? '');
                      //     _sendCommand(command);
                      //   },
                      // ),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              setState(() => _selectedCommand = cmd['cmd']);

                              _showDefaultCommandDialog(
                                context,
                                cmd['cmd'] ?? '',
                              );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Custom Commands",
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 35,
                        width: 35,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark
                                    ? tWhite.withOpacity(0.1)
                                    : tBlack.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.4)
                                        : tBlack.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          onPressed: () {
                            _showCustomCommandDialog(context);
                          },
                          child: Icon(
                            Icons.add,
                            color: isDark ? tWhite : tBlack,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: _buildCommandLogTable(isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final device = widget.device;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                    future: getAddressFromLocationStringWeb(
                      deviceDetailsModel?.lat != null &&
                              deviceDetailsModel?.long != null
                          ? '${deviceDetailsModel!.lat},${deviceDetailsModel!.long}'
                          : "",
                    ),
                    builder: (context, snapshot) {
                      final displayStatus =
                          mode == 'EV Fleet'
                              ? (deviceDetailsModel?.status ??
                                  device.status ??
                                  '') // Use regular status for EV
                              : (deviceDetailsModel?.lstatus ??
                                  device.status ??
                                  '');
                      return buildDeviceCard(
                        isDark: isDark,
                        imei: deviceDetailsModel?.imei ?? device.imei ?? '',
                        vehicleNumber: deviceDetailsModel?.vehicleNumber ?? '',
                        status: displayStatus,
                        fuel: device.soc?.toString() ?? '',
                        odo: device.odometer?.toString() ?? '',
                        trips: (device.totalTrips ?? '').toString(),
                        alerts: (device.totalAlerts ?? '').toString(),
                        location:
                            (deviceDetailsModel?.address ?? '').toString(),
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
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: isDark ? tBlack : tWhite,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDark
                                                    ? Colors.white.withOpacity(
                                                      0.7,
                                                    )
                                                    : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Confirm Action",
                                              style: GoogleFonts.urbanist(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? tWhite : tBlack,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            /// 🔹 Content
                                            Text(
                                              "Are you sure you want to send this command?",
                                              style: GoogleFonts.urbanist(
                                                fontSize: 16,
                                                color: isDark ? tWhite : tBlack,
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            /// 🔹 Actions
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text(
                                                    "Cancel",
                                                    style: GoogleFonts.urbanist(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          isDark
                                                              ? tWhite
                                                                  .withOpacity(
                                                                    0.7,
                                                                  )
                                                              : tBlack
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: tBlue,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text(
                                                    "Ok",
                                                    style: GoogleFonts.urbanist(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: tWhite,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                      // ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: tBlue,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 15,
                      //       vertical: 8,
                      //     ),
                      //   ),
                      //   child: Text(
                      //     "Send",
                      //     style: GoogleFonts.urbanist(
                      //       color: tWhite,
                      //       fontSize: 13,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      //   onPressed: () {
                      //     final command =
                      //         _customCommandController.text.isNotEmpty
                      //             ? _customCommandController.text
                      //             : (_selectedCommand ?? '');
                      //     _sendCommand(command);
                      //   },
                      // ),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              setState(() => _selectedCommand = cmd['cmd']);

                              _showDefaultCommandDialog(
                                context,
                                cmd['cmd'] ?? '',
                              );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Custom Commands",
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 35,
                        width: 35,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark
                                    ? tWhite.withOpacity(0.1)
                                    : tBlack.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.4)
                                        : tBlack.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          onPressed: () {
                            _showCustomCommandDialog(context);
                          },
                          child: Icon(
                            Icons.add,
                            color: isDark ? tWhite : tBlack,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: _buildCommandLogTable(isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
        // SizedBox(width: 15),
        // Expanded(flex: 5, child: _buildCommandLogTable(isDark)),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    final device = widget.device;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
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
                  future: getAddressFromLocationStringWeb(
                    device.location ?? '',
                  ),

                  builder: (context, snapshot) {
                    final address =
                        snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData
                            ? snapshot.data!
                            : 'Fetching location...';

                    final displayStatus =
                        mode == 'EV Fleet'
                            ? (deviceDetailsModel?.status ??
                                device.status ??
                                '') // Use regular status for EV
                            : (deviceDetailsModel?.lstatus ??
                                device.status ??
                                '');
                    return buildDeviceCard(
                      isDark: isDark,
                      imei: deviceDetailsModel?.imei ?? device.imei ?? '',
                      vehicleNumber: deviceDetailsModel?.vehicleNumber ?? '',
                      status: displayStatus,
                      fuel: device.soc?.toString() ?? '',
                      odo: device.odometer?.toString() ?? '',
                      trips: (device.totalTrips ?? '').toString(),
                      alerts: (device.totalAlerts ?? '').toString(),
                      location: deviceDetailsModel?.address ?? '',
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
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      width: 400,
                                      decoration: BoxDecoration(
                                        color: isDark ? tBlack : tWhite,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color:
                                              isDark
                                                  ? Colors.white.withOpacity(
                                                    0.7,
                                                  )
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Confirm Action",
                                            style: GoogleFonts.urbanist(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? tWhite : tBlack,
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          /// 🔹 Content
                                          Text(
                                            "Are you sure you want to send this command?",
                                            style: GoogleFonts.urbanist(
                                              fontSize: 16,
                                              color: isDark ? tWhite : tBlack,
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          /// 🔹 Actions
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  "Cancel",
                                                  style: GoogleFonts.urbanist(
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isDark
                                                            ? tWhite
                                                                .withOpacity(
                                                                  0.7,
                                                                )
                                                            : tBlack
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 10),

                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: tBlue,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  "Ok",
                                                  style: GoogleFonts.urbanist(
                                                    fontWeight: FontWeight.w700,
                                                    color: tWhite,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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
                    // ElevatedButton(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: tBlue,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     padding: EdgeInsets.symmetric(
                    //       horizontal: 15,
                    //       vertical: 8,
                    //     ),
                    //   ),
                    //   child: Text(
                    //     "Send",
                    //     style: GoogleFonts.urbanist(
                    //       color: tWhite,
                    //       fontSize: 13,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    //   onPressed: () {
                    //     final command =
                    //         _customCommandController.text.isNotEmpty
                    //             ? _customCommandController.text
                    //             : (_selectedCommand ?? '');
                    //     _sendCommand(command);
                    //   },
                    // ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _selectedCommand = cmd['cmd']);

                            _showDefaultCommandDialog(
                              context,
                              cmd['cmd'] ?? '',
                            );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Custom Commands",
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 35,
                      width: 35,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? tWhite.withOpacity(0.1)
                                  : tBlack.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.4)
                                      : tBlack.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        onPressed: () {
                          _showCustomCommandDialog(context);
                        },
                        child: Icon(
                          Icons.add,
                          color: isDark ? tWhite : tBlack,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
        Expanded(flex: 5, child: _buildCommandLogTable(isDark)),
      ],
    );
  }

  Widget _buildCommandLogTable(bool isDark) {
    int totalPages = (totalCount / rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    String formatResponse(String? data) {
      return (data ?? '').replaceAll('\r', '\n').trim();
    }

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
              Expanded(
                child:
                    _commandLogsApi.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'icons/nodata1.svg',
                                height: 120,
                                width: 120,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No command logs found",
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Scrollbar(
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark
                                            ? tGreen8.withOpacity(0.15)
                                            : tGreen8.withOpacity(0.05),
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
                                        DataColumn(
                                          label: Text('Received Data'),
                                        ),
                                        DataColumn(label: Text('User')),
                                      ],
                                      rows:
                                          _commandLogsApi.map((cmd) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(formatDate(cmd.date)),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: getTypeColor(
                                                        cmd.type ?? '',
                                                      ).withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      cmd.type ?? '',
                                                      style:
                                                          GoogleFonts.urbanist(
                                                            color: getTypeColor(
                                                              cmd.type ?? '',
                                                            ),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(cmd.commandSent ?? ''),
                                                ),
                                                // DataCell(
                                                //   Text(cmd.dataReceived ?? ''),
                                                // ),
                                                DataCell(
                                                  SizedBox(
                                                    width: 250,
                                                    child: SelectableText(
                                                      formatResponse(
                                                        cmd.dataReceived,
                                                      ),
                                                      style:
                                                          GoogleFonts.urbanist(
                                                            fontSize: 12,
                                                            color:
                                                                isDark
                                                                    ? tWhite
                                                                    : tBlack,
                                                          ),
                                                    ),
                                                  ),
                                                ),

                                                DataCell(
                                                  Text(cmd.userId ?? ''),
                                                ),
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
                    color: isSelected ? tGreen8 : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isSelected
                              ? tGreen8
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
                  borderSide: BorderSide(color: tGreen8, width: 1),
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
        statusColor = tBlue;
        break;
      case 'non coverage':
        statusColor = const Color(0xFF9C27B0);
        break;
      default:
        statusColor = tBlack;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tTransparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
          width: 0.4,
        ),
      ),
      padding: const EdgeInsets.all(
        12,
      ), // Slightly increased padding for mobile
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mobile-optimized top row
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle info card (full width on mobile)
                  Container(
                    width: double.infinity,
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
                            gradient: SweepGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                            ),
                          ),
                          child: Text(
                            imei,
                            style: GoogleFonts.urbanist(
                              fontSize: isMobile ? 11 : 16,
                              fontWeight: FontWeight.w700,
                              color: tWhite,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            vehicleNumber,
                            style: GoogleFonts.urbanist(
                              fontSize: isMobile ? 11 : 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? tWhite : tBlack,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Status badge (below on mobile)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: [statusColor, statusColor.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tWhite,
                      ),
                    ),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 250,
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
                            gradient: SweepGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.6),
                              ],
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
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
                        color: tWhite,
                      ),
                    ),
                  ),
                ],
              ),

          Divider(
            color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
            thickness: 0.3,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 30 : 36,
                height: isMobile ? 28 : 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: Center(
                  child: SvgPicture.asset(
                    'icons/geofence.svg',
                    width: isMobile ? 12 : 16,
                    height: isMobile ? 12 : 16,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.urbanist(
                    fontSize: isMobile ? 12 : 13,
                    color: isDark ? tWhite : tBlack,
                    height: 1.3,
                  ),
                  maxLines: isMobile ? 3 : null,
                  overflow: isMobile ? TextOverflow.ellipsis : null,
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
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    final double cardHeight = isMobile ? 70 : 90;
    final double iconSize = isMobile ? 38 : 52;
    final double iconSvgSize = isMobile ? 20 : 26;
    final double fontSize = isMobile ? 12 : 15;
    final double horizontalPadding = isMobile ? 10 : 14;
    final double borderRadius = 20;

    Widget card(bool hover) {
      return GestureDetector(
        onTap: () => onToggle(!isEnabled),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius + 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: hover ? 20 : 15,
                sigmaY: hover ? 20 : 15,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: cardHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isMobile ? 6 : 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),

                  // Glass background
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.15),

                  border: Border.all(
                    width: hover ? 3 : 1.8,
                    color: color.withOpacity(
                      hover
                          ? 0.65
                          : isDark
                          ? 0.30
                          : 0.45,
                    ),
                  ),

                  boxShadow: [
                    BoxShadow(
                      blurRadius: hover ? 20 : 12,
                      spreadRadius: hover ? 2 : 0,
                      color: color.withOpacity(hover ? 0.18 : 0.10),
                    ),
                  ],
                ),

                child: Stack(
                  children: [
                    // Glass Shine Effect
                    Positioned.fill(child: IgnorePointer(child: Container())),

                    Row(
                      children: [
                        // Glass Icon Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.10),

                            border: Border.all(
                              color: color.withOpacity(hover ? 0.35 : 0.20),
                              width: hover ? 2 : 1.2,
                            ),

                            boxShadow: [
                              BoxShadow(
                                blurRadius: hover ? 18 : 10,
                                color: color.withOpacity(0.15),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: hover ? 1.1 : 1.0,
                              child: SvgPicture.asset(
                                icon,
                                width: iconSvgSize,
                                height: iconSvgSize,
                                color: color,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: isMobile ? 10 : 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: GoogleFonts.urbanist(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // AnimatedContainer(
                                  //   duration: const Duration(milliseconds: 300),
                                  //   width: 8,
                                  //   height: 8,
                                  //   decoration: BoxDecoration(
                                  //     shape: BoxShape.circle,
                                  //     color:
                                  //         isEnabled ? Colors.green : Colors.red,
                                  //     boxShadow: [
                                  //       BoxShadow(
                                  //         blurRadius: 8,
                                  //         color: (isEnabled
                                  //                 ? Colors.green
                                  //                 : Colors.red)
                                  //             .withOpacity(0.5),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),

                              SizedBox(height: isMobile ? 4 : 6),

                              _buildToggle(
                                context,
                                isEnabled,
                                onToggle,
                                isDark,
                                color,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return HoverWrapper(builder: (hover) => card(hover));
  }

  Widget _buildToggle(
    BuildContext context,
    bool isEnabled,
    Function(bool) onToggle,
    bool isDark,
    Color accentColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    final double containerWidth = isMobile ? 56 : 80;
    final double containerHeight = isMobile ? 24 : 32;
    final double knobSize = isMobile ? 20 : 28;
    final double borderRadius = isMobile ? 12 : 16;

    return GestureDetector(
      onTap: () => onToggle(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors:
                isEnabled
                    ? [
                      accentColor.withOpacity(0.8),
                      accentColor.withOpacity(0.95),
                      accentColor.withOpacity(0.8),
                    ]
                    : isDark
                    ? [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.12),
                    ]
                    : [
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.06),
                      Colors.black.withOpacity(0.12),
                    ],
          ),
          border: Border.all(
            color:
                isEnabled
                    ? accentColor.withOpacity(0.4)
                    : isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 0,
                color: accentColor.withOpacity(0.3),
              ),
            BoxShadow(
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 1),
              color:
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: isMobile ? 4 : 6),
                  child: Text(
                    "OFF",
                    style: GoogleFonts.urbanist(
                      fontSize: isMobile ? 7 : 12,
                      fontWeight: FontWeight.w800,
                      color: tRed,

                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: isMobile ? 4 : 6),
                  child: Text(
                    "ON",
                    style: GoogleFonts.urbanist(
                      fontSize: isMobile ? 7 : 12,
                      fontWeight: FontWeight.w800,
                      color: tGreen,

                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            // Knob with spring animation
            AnimatedAlign(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              alignment:
                  isEnabled ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 3),
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [Colors.white, Color(0xFFE8E8E8)]
                            : [Colors.white, Color(0xFFF5F5F5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      spreadRadius: 0,
                      color:
                          isEnabled
                              ? accentColor.withOpacity(0.5)
                              : Colors.black.withOpacity(0.15),
                      offset: Offset(0, 2),
                    ),
                    BoxShadow(
                      blurRadius: 3,
                      spreadRadius: 0,
                      color:
                          isEnabled
                              ? accentColor.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                      offset: Offset(0, 0),
                    ),
                    if (isEnabled)
                      BoxShadow(
                        blurRadius: 16,
                        spreadRadius: 2,
                        color: accentColor.withOpacity(0.15),
                      ),
                  ],
                  border: Border.all(
                    color:
                        isEnabled
                            ? accentColor.withOpacity(0.4)
                            : Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      isEnabled ? "ON" : "OFF",
                      key: ValueKey(isEnabled),
                      style: GoogleFonts.urbanist(
                        fontSize: isMobile ? 7 : 9,
                        fontWeight: FontWeight.w800,
                        color: isEnabled ? tGreen : tRed,
                      ),
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
}
