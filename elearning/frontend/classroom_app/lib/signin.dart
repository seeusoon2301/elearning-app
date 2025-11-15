import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final email = TextEditingController();
  final pass = TextEditingController();
  String error = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: pass, decoration: InputDecoration(labelText: "Password")),
            SizedBox(height: 20),
            Text(error, style: TextStyle(color: Colors.red)),
            ElevatedButton(
  onPressed: () async {
    try {
      final data = await ApiService.login(email.text, pass.text);

      // Lưu email vào SharedPreferences để HomePage dùng
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("userEmail", data['user']['email']);
      await prefs.setString("token", data['token']); // nếu muốn lưu token

      // Chuyển sang HomePage
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomePage()));
    } catch (e) {
      setState(() => error = e.toString());
    }
  },
  child: Text("Login"),
),

          ],
        ),
      ),
    );
  }
}
