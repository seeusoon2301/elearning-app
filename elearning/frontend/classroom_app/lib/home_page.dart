import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List courses = [];
  String email = "";
  int selectedIndex = 0;

  final menuItems = ["Lớp học", "Thông báo", "Chỉnh sửa thông tin", "Forum"];

  @override
  void initState() {
    super.initState();
    loadEmailAndCourses();
  }

  Future<void> loadEmailAndCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString("userEmail") ?? "";

    if (storedEmail.isEmpty) {
      // Email chưa có, không gọi API
      print("Email student chưa được lưu!");
      return;
    }

    setState(() => email = storedEmail);
    print("Email student: $email");

    try {
      final data = await ApiService.getStudentCourses(email);
      print("Fetched courses: $data");
      setState(() => courses = data);
    } catch (e) {
      print("Error fetching courses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navbar dọc
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: menuItems
                .map((e) => NavigationRailDestination(
                      icon: Icon(Icons.circle),
                      selectedIcon: Icon(Icons.check_circle),
                      label: Text(e),
                    ))
                .toList(),
          ),
          VerticalDivider(thickness: 1, width: 1),
          // Nội dung chính
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                // 0 - Lớp học: List Course
                courses.isEmpty
                    ? Center(child: Text("Chưa có lớp học hoặc đang tải..."))
                    : ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Card(
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              title: Text(course['name']),
                              subtitle:
                                  Text("Giảng viên: ${course['instructorName']}"),
                              leading: course['coverImage'] != null
                                  ? Image.network(course['coverImage'],
                                      width: 60, height: 60, fit: BoxFit.cover)
                                  : Icon(Icons.book),
                              onTap: () {
                                // TODO: navigate to course detail page
                              },
                            ),
                          );
                        },
                      ),
                // 1 - Thông báo
                Center(child: Text("Thông báo")),
                // 2 - Chỉnh sửa thông tin
                Center(child: Text("Chỉnh sửa thông tin")),
                // 3 - Forum
                Center(child: Text("Forum")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
