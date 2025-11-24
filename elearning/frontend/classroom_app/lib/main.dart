import 'package:classroom_app/providers/semester_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'signin.dart';
import 'role_provider.dart';
import 'theme_provider.dart';
import 'instructor_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? initialRole = prefs.getString('role');
  runApp(MyApp(initialRole: initialRole));
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider(role: initialRole)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SemesterProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'E-Learning App • TDTU',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: themeProvider.themeMode,
            home: Consumer<RoleProvider>(
              builder: (context, roleProvider, child) {
                if (roleProvider.role == null) {
                  return const SignIn();
                }
                return roleProvider.role == "instructor"
                    ? const InstructorDashboard()
                    : const Home();
              },
            ),
          );
        },
      ),
    );
  }
}