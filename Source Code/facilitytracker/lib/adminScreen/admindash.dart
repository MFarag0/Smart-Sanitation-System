import 'package:facilitytracker/widgets/sidebar_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashScreen extends StatefulWidget {
  const AdminDashScreen({super.key});

  @override
  State<AdminDashScreen> createState() => _AdminDashScreenState();
}

class _AdminDashScreenState extends State<AdminDashScreen> {
  double facility1WaterPercentage = 0.97;
  double facility1SoapPercentage = 0.99;
  double facility1PeoplePercentage = 0.10;
  
  List<Map<String, dynamic>> staticFacilities = [
    {
      'name': 'Facility 2',
      'zone': 'Zone A',
      'peoplePercentage': 0.60,
      'waterPercentage': 0.45,
      'soapPercentage': 0.30,
    },
    {
      'name': 'Facility 3',
      'zone': 'Zone B',
      'peoplePercentage': 0.35,
      'waterPercentage': 0.90,
      'soapPercentage': 0.85,
    },
    {
      'name': 'Facility 4',
      'zone': 'Zone B',
      'peoplePercentage': 0.75,
      'waterPercentage': 0.20,
      'soapPercentage': 0.15,
    },
  ];

  List<Map<String, dynamic>> get allFacilities {
    return [
      {
        'name': 'Facility 1',
        'zone': 'Zone A',
        'peoplePercentage': facility1PeoplePercentage,
        'waterPercentage': facility1WaterPercentage,
        'soapPercentage': facility1SoapPercentage,
      },
      ...staticFacilities,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 800;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;
    final primaryColor = Color.fromARGB(255, 16, 134, 185);
    final warningColor = Color(0xFFF59E0B);
    final lowColor = Color(0xFFEF4444);

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
            leading: isPhone
                ? IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  )
                : null,
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
          drawer: isPhone ? Drawer(child: SidebarAdmin()) : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!isPhone) SidebarAdmin(),
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
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Monitor all facilities and their supply status",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: allFacilities.length,
                            itemBuilder: (context, index) {
                              final facility = allFacilities[index];
                              final peoplePercent = (facility['peoplePercentage'] as double) * 100;
                              final waterPercent = (facility['waterPercentage'] as double) * 100;
                              final soapPercent = (facility['soapPercentage'] as double) * 100;
                              
                              Color getStatusColor(double percentage) {
                                if (percentage > 50) return primaryColor;
                                if (percentage > 30) return warningColor;
                                return lowColor;
                              }
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.business,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                facility['name'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                facility['zone'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.group,
                                                    size: 16,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Population',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: facility['peoplePercentage'] as double,
                                                backgroundColor: Color(0xFFE2E8F0),
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  peoplePercent > 80 ? warningColor : (peoplePercent > 90 ? lowColor : primaryColor),
                                                ),
                                                minHeight: 8,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${peoplePercent.toInt()}%',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: peoplePercent > 80 ? warningColor : (peoplePercent > 90 ? lowColor : primaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.water_drop,
                                                    size: 16,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Water Supply',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: facility['waterPercentage'] as double,
                                                backgroundColor: Color(0xFFE2E8F0),
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  getStatusColor(waterPercent),
                                                ),
                                                minHeight: 8,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${waterPercent.toInt()}%',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: getStatusColor(waterPercent),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.soap,
                                                    size: 16,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Soap Supply',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: facility['soapPercentage'] as double,
                                                backgroundColor: Color(0xFFE2E8F0),
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  getStatusColor(soapPercent),
                                                ),
                                                minHeight: 8,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${soapPercent.toInt()}%',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: getStatusColor(soapPercent),
                                                ),
                                              ),
                                            ],
                                          ),
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
                  ),
                ),
              ],
            ),
          ),
    );
  }
}