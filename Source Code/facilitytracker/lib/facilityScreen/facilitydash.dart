import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:facilitytracker/widgets/sidebar.dart';
import 'package:facilitytracker/facilityScreen/requests.dart';

class FacilityDashScreen extends StatefulWidget {
  const FacilityDashScreen({super.key});

  @override
  State<FacilityDashScreen> createState() => _FacilityDashScreenState();
}

class _FacilityDashScreenState extends State<FacilityDashScreen> {
  
  int waterLevel = 0;
  int soapLevel = 0; 
  int restroom1Level = 0;
  int populationLevel = 0;

  // Capacities
  int maxPopulation = 200;  // Assuming max population 200
  int soapCapacity = 200;   // Assuming max height of the soap bottle is 200units
  int waterCapacity = 200;  // Assuming max height of the water tank is 50units

  
  String rawMessage = "Connecting...";
  Timer? timer;


  int restroom1BaselineUsage = 0;
  
  List<String> sanitationStatuses = [
    'Due for cleaning',
    'Clean',
    'Clean',
    'Due for cleaning',
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }


  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1/sensorsdata"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) return;

      final msg = response.body.trim().replaceAll('\r', '');
      final parts = msg.split('|');

      
      if (parts.isEmpty || parts[0] != "FacilityA" || parts.length < 3) {
        if (!mounted) return;
        setState(() => rawMessage = "Invalid format of incoming data.");
        return;
      }

      
      final Map<String, int> kv = {};
      for (int i = 1; i + 1 < parts.length; i += 2) {
        final key = parts[i].trim().toUpperCase();
        final valueStr = parts[i + 1].trim();
        final value = int.tryParse(valueStr);
        if (value != null) {
          kv[key] = value;
        }
      }

      if (!mounted) return;
      setState(() {
        rawMessage = "Connected.";
        waterLevel = kv["WATER"] ?? waterLevel;
        populationLevel = kv["POPULATION"] ?? populationLevel;
        soapLevel = kv["SOAP"] ?? soapLevel;
        
        int newRestroom1Level = kv["RR1"] ?? restroom1Level;
        restroom1Level = newRestroom1Level;
        
        
        if (restroom1Level - restroom1BaselineUsage >= 10) {
          sanitationStatuses[0] = 'Due for cleaning';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => rawMessage = "Connection error");
    }
  }

  
  double _ratio(int value, int capacity) {
    if (capacity <= 0) return 0.0;
    final r = value / capacity;
    if (r < 0) return 0.0;
    if (r > 1) return 1.0;
    return r;
  }

  Color _statusColor({
    required String title,
    required double ratio,
    required Color primary,
    required Color warning,
    required Color low,
  }) {
    
    if (title == "Traffic") {
      if (ratio >= 0.80) return low; 
      if (ratio >= 0.40) return warning;
      return primary;
    }

   
    if (ratio <= 0.20) return low;
    if (ratio <= 0.35) return warning;
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 800;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;

    final primaryColor = const Color.fromARGB(255, 16, 134, 185);
    final warningColor = const Color(0xFFF59E0B);
    final lowColor = const Color(0xFFEF4444);
    final cardBg = Colors.white;

    final items = [
      {
        'title': 'Traffic',
        'icon': Icons.group,
        'value': populationLevel,
        'capacity': maxPopulation,
      },
      {
        'title': 'Water Supply',
        'icon': Icons.water_drop,
        'value': waterLevel,
        'capacity': waterCapacity,
      },
      {
        'title': 'Soap Supply',
        'icon': Icons.soap,
        'value': soapLevel,
        'capacity': soapCapacity,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Facility Dashboard",
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
              colors: [primaryColor, const Color.fromARGB(255, 70, 229, 184)],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 5, horizontal: 32),
                      child: Row(
                        children: [
                          Text(
                            'Zone 1 - Facility A',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Status: $rawMessage",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isPhone ? 1 : (isTablet ? 2 : 3),
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 70,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          final title = items[index]['title'] as String;
                          final icon = items[index]['icon'] as IconData;
                          final value = items[index]['value'] as int;
                          final capacity = items[index]['capacity'] as int;

                          
                          final effectiveValue = (title == 'Water Supply' || title == 'Soap Supply') 
                              ? (capacity - value) 
                              : value;
                          final ratio = _ratio(effectiveValue, capacity);
                          final percent = (ratio * 100).toStringAsFixed(0);

                          final color = _statusColor(
                            title: title,
                            ratio: ratio,
                            primary: primaryColor,
                            warning: warningColor,
                            low: lowColor,
                          );

                          return Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CircularProgressIndicator(
                                        value: ratio,
                                        strokeWidth: 6,
                                        backgroundColor:
                                            primaryColor.withOpacity(0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(color),
                                      ),
                                    ),
                                    Icon(icon, size: 36, color: primaryColor),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title == "Traffic"
                                      ? (ratio >= 0.80
                                          ? 'High'
                                          : ratio >= 0.40
                                              ? 'Medium'
                                              : 'Low')
                                      : '$percent%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Extra details
                                if (title == "Traffic")
                                  Text(
                                    '$populationLevel visitors today',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),

                                if (title == "Water Supply" || title == "Soap Supply")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: TextButton(
                                      onPressed: () async {
                                        
                                        await RequestsScreen.sendAutomatedMessage(
                                          'Request for $title refill'
                                        );

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$title refill requested!'),
                                            duration: const Duration(seconds: 4),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 170, 175, 76),
                                        foregroundColor: Colors.white,
                                        textStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: const Text("Request Refill"),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Restrooms Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Pit Latrine Level: ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                  Text(
                                    'LOW',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isPhone ? 1 : (isTablet ? 2 : 4),
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 2.2,
                            ),
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.wc,
                                        color: primaryColor, size: 32),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Restroom ${index + 1}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sanitation: ${sanitationStatuses[index]}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: sanitationStatuses[index] == 'Due for cleaning'
                                                ? Colors.red
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              sanitationStatuses[index] = 'Clean';
                                              
                                              if (index == 0) {
                                                restroom1BaselineUsage = restroom1Level;
                                              }
                                            });

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Restroom ${index + 1} marked as cleaned!',
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white),
                                                ),
                                                duration: const Duration(seconds: 3),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            textStyle: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: const Text("Mark as Cleaned"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
