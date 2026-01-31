import 'dart:async';
import 'package:facilitytracker/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class SensorsDataScreen extends StatefulWidget {
  const SensorsDataScreen({super.key});

  @override
  State<SensorsDataScreen> createState() => _SensorsDataScreenState();
}

class _SensorsDataScreenState extends State<SensorsDataScreen> {
  Timer? timer;
  Map<String, bool> sensorStatus = {
    'Population': false,
    'Water': false,
    'Soap': false,
    'Pit Latrine': false,
    'RR1': false,
    'RR2': false,
    'RR3': false,
    'RR4': false,
  };

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => fetchSensorData());
    fetchSensorData();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchSensorData() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1/sensorsdata"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) return;

      final msg = response.body.trim().replaceAll('\r', '');
      final parts = msg.split('|');

      if (parts.isEmpty || parts[0] != "FacilityA" || parts.length < 3) {
        return;
      }

      // Parse key-value pairs and update sensor status
      final Map<String, bool> newStatus = {
        'Population': false,
        'Water': false,
        'Soap': false,
        'RR1': false,
        'RR2': false,
        'RR3': false,
        'RR4': false,
      };

      for (int i = 1; i + 1 < parts.length; i += 2) {
        final key = parts[i].trim();
        if (newStatus.containsKey(key)) {
          newStatus[key] = true; 
        }
      }

      if (!mounted) return;
      setState(() {
        sensorStatus = newStatus;
      });
    } catch (e) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 650;
    final primaryColor = Color.fromARGB(255, 16, 134, 185);
    final isTablet = screenWidth >= 650 && screenWidth < 1200;
    final cardBg = Colors.white;

    return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              "Sensors Status",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            toolbarHeight: 80,
            backgroundColor: primaryColor,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, Color.fromARGB(255, 70, 229, 184)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Row(
              children: [
                Sidebar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: GridView.builder(
                            padding: EdgeInsets.all(20),
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: 5,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isPhone ? 1 : (isTablet ? 2 :  5),
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 30,
                              childAspectRatio: 0.75,
                            ),
                            itemBuilder: (context, index) {
                              final items = [
                                {
                                  'title': 'Traffic Sensor',
                                  'icon': Icons.people, 
                                  'statusKey': 'Population',
                                  'isMultiRoom': false,
                                },
                                {
                                  'title': 'Water Tank Sensor', 
                                  'icon': Icons.water_drop,
                                  'statusKey': 'Water',
                                  'isMultiRoom': false,
                                },
                                {
                                  'title': 'Soap Supply Sensor', 
                                  'icon': Icons.soap,
                                  'statusKey': 'Soap',
                                  'isMultiRoom': false,
                                },
                                {
                                  'title': 'Pit Latrine Sensor', 
                                  'icon': Icons.bathroom,
                                  'statusKey': 'Pit Latrine',
                                  'isMultiRoom': false,
                                },
                                {
                                  'title': 'Toilet Access Sensors', 
                                  'icon': Icons.wc,
                                  'statusKey': null,
                                  'isMultiRoom': true,
                                  'rooms': [
                                    {'name': 'Restroom 1', 'statusKey': 'RR1'},
                                    {'name': 'Restroom 2', 'statusKey': 'RR2'},
                                    {'name': 'Restroom 3', 'statusKey': 'RR3'},
                                    {'name': 'Restroom 4', 'statusKey': 'RR4'},
                                  ],
                                },
                                
                                
                              ];
                              
                              var title = items[index]['title'] as String;
                              var icon = items[index]['icon'] as IconData;
                              var statusKey = items[index]['statusKey'] as String?;
                              var isMultiRoom = items[index]['isMultiRoom'] as bool;
                              
                            
                              var status = 'Inactive';
                              if (statusKey != null && sensorStatus[statusKey] == true) {
                                status = 'Active';
                              } else if (isMultiRoom) {
                                
                                final rooms = items[index]['rooms'] as List<Map<String, String>>;
                                for (var room in rooms) {
                                  if (sensorStatus[room['statusKey']!] == true) {
                                    status = 'Active';
                                    break;
                                  }
                                }
                              }
                              
                              final activeColor = Color.fromARGB(255, 16, 134, 185);
                              final inactiveColor = Color(0xFFEF4444);
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 8),
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: status == 'Active' 
                                            ? activeColor.withOpacity(0.1)
                                            : inactiveColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 36,
                                        color: status == 'Active' ? activeColor : inactiveColor,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    
                                    
                                    if (!isMultiRoom) ...[
                                      
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: status == 'Active' 
                                              ? activeColor.withOpacity(0.1)
                                              : inactiveColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'Active' ? activeColor : inactiveColor,
                                          ),
                                        ),
                                      ),
                                    ] else ...[

                                      SizedBox(height: 8),
                                      Column(
                                        children: (items[index]['rooms'] as List<Map<String, String>>).map((room) {
                                          final roomStatusKey = room['statusKey']!;
                                          final roomStatus = sensorStatus[roomStatusKey] == true ? 'Active' : 'Inactive';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    room['name']!,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: roomStatus == 'Active' 
                                                        ? activeColor
                                                        : inactiveColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  roomStatus,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: roomStatus == 'Active' 
                                                        ? activeColor
                                                        : inactiveColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    
                                  ],
                                ),
                              );
                            }
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