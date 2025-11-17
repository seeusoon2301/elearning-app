import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'signin.dart';
import 'role_provider.dart';
import 'theme_provider.dart';
import 'instructor_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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