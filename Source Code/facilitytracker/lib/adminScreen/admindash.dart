import 'dart:async';
import 'package:facilitytracker/widgets/sidebar_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AdminDashScreen extends StatefulWidget {
  const AdminDashScreen({super.key});

  @override
  State<AdminDashScreen> createState() => _AdminDashScreenState();
}

class _AdminDashScreenState extends State<AdminDashScreen> {
  int facilityAWater = 0;
  int facilityASoap = 0;
  int facilityATraffic = 0;
  int waterCapacity = 200;
  int soapCapacity = 200;
  int maxTraffic = 200;
  
  Timer? timer;
  
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => fetchFacilityAData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchFacilityAData() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1/facilitydata"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) return;

      final msg = response.body.trim().replaceAll('\r', '');
      final parts = msg.split('|');

      if (parts.isEmpty || parts[0] != "FacilityA" || parts.length < 3) {
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
        facilityAWater = kv["WATER"] ?? facilityAWater;
        facilityATraffic = kv["POPULATION"] ?? facilityATraffic;
        facilityASoap = kv["SOAP"] ?? facilityASoap;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Map<String, dynamic> getFacilityData(int zone, String facility) {
    // Zone 1 - Facility A has real data
    if (zone == 1 && facility == 'A') {
      return {
        'water': facilityAWater,
        'soap': facilityASoap,
        'traffic': facilityATraffic,
        'waterPercent': ((waterCapacity - facilityAWater) / waterCapacity).clamp(0.0, 1.0),
        'soapPercent': ((soapCapacity - facilityASoap) / soapCapacity).clamp(0.0, 1.0),
        'trafficPercent': (facilityATraffic / maxTraffic).clamp(0.0, 1.0),
      };
    }
    
    // Static data for all other facilities
    final staticData = {
      '1-B': {'water': 150, 'soap': 180, 'traffic': 45},
      '1-C': {'water': 95, 'soap': 110, 'traffic': 120},
      '2-A': {'water': 180, 'soap': 160, 'traffic': 85},
      '2-B': {'water': 60, 'soap': 50, 'traffic': 150},
      '2-C': {'water': 170, 'soap': 190, 'traffic': 30},
      '3-A': {'water': 40, 'soap': 35, 'traffic': 180},
      '3-B': {'water': 190, 'soap': 175, 'traffic': 60},
      '3-C': {'water': 130, 'soap': 140, 'traffic': 95},
    };
    
    final key = '$zone-$facility';
    final data = staticData[key]!;
    
    return {
      'water': data['water'],
      'soap': data['soap'],
      'traffic': data['traffic'],
      'waterPercent': ((waterCapacity - data['water']!) / waterCapacity).clamp(0.0, 1.0),
      'soapPercent': ((soapCapacity - data['soap']!) / soapCapacity).clamp(0.0, 1.0),
      'trafficPercent': (data['traffic']! / maxTraffic).clamp(0.0, 1.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 800;
    final primaryColor = Color.fromARGB(255, 16, 134, 185);
    final warningColor = Color(0xFFF59E0B);
    final lowColor = Color(0xFFEF4444);

    Color getStatusColor(double percentage) {
      if (percentage > 0.5) return primaryColor;
      if (percentage > 0.3) return warningColor;
      return lowColor;
    }
    
    Color getTrafficColor(double percentage) {
      if (percentage < 0.8) return primaryColor;
      if (percentage < 0.9) return warningColor;
      return lowColor;
    }

    Widget buildFacilityCard(int zone, String facilityLetter) {
      final data = getFacilityData(zone, facilityLetter);
      final waterPercent = data['waterPercent'] as double;
      final soapPercent = data['soapPercent'] as double;
      final trafficPercent = data['trafficPercent'] as double;
      
      String getTrafficStatus(double percent) {
        if (percent < 0.8) return 'LOW';
        if (percent < 0.9) return 'MEDIUM';
        return 'HIGH';
      }
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Facility $facilityLetter',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Circular Progress Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Traffic
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: trafficPercent,
                            backgroundColor: Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getTrafficColor(trafficPercent),
                            ),
                            strokeWidth: 6,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: getTrafficColor(trafficPercent),
                            ),
                            Text(
                              getTrafficStatus(trafficPercent),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: getTrafficColor(trafficPercent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Traffic',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                
                // Water Supply
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: waterPercent,
                            backgroundColor: Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getStatusColor(waterPercent),
                            ),
                            strokeWidth: 6,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 16,
                              color: getStatusColor(waterPercent),
                            ),
                            Text(
                              '${(waterPercent * 100).round()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(waterPercent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Water',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                
                // Soap Supply
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: soapPercent,
                            backgroundColor: Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getStatusColor(soapPercent),
                            ),
                            strokeWidth: 6,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.soap,
                              size: 16,
                              color: getStatusColor(soapPercent),
                            ),
                            Text(
                              '${(soapPercent * 100).round()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(soapPercent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Soap',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildZoneSection(int zoneNumber) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone $zoneNumber',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 237, 189, 126),
            ),
          ),
          SizedBox(height: 16),
          isPhone
              ? Column(
                  children: [
                    buildFacilityCard(zoneNumber, 'A'),
                    SizedBox(height: 12),
                    buildFacilityCard(zoneNumber, 'B'),
                    SizedBox(height: 12),
                    buildFacilityCard(zoneNumber, 'C'),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: buildFacilityCard(zoneNumber, 'A')),
                    SizedBox(width: 16),
                    Expanded(child: buildFacilityCard(zoneNumber, 'B')),
                    SizedBox(width: 16),
                    Expanded(child: buildFacilityCard(zoneNumber, 'C')),
                  ],
                ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
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
              colors: [Color.fromARGB(255, 237, 189, 126), Color.fromARGB(255, 229, 221, 70)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            SidebarAdmin(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Facilities Overview",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 237, 189, 126),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Monitor all facilities across zones",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      buildZoneSection(1),
                      SizedBox(height: 32),
                      
                      buildZoneSection(2),
                      SizedBox(height: 32),
                      
                      buildZoneSection(3),
                    ],
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