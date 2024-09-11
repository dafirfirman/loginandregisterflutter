import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jpr/loginScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In

class RegScreen extends StatefulWidget {
  final Function(ThemeMode) updateThemeMode;

  const RegScreen({Key? key, required this.updateThemeMode}) : super(key: key);

  @override
  _RegScreenState createState() => _RegScreenState();
}

class _RegScreenState extends State<RegScreen> {
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _isEmailValid = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Inisialisasi GoogleSignIn

  // Method to validate email
  bool _isValidEmail(String email) {
    String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
    RegExp regex = RegExp(emailPattern);
    bool isValid = regex.hasMatch(email);
    setState(() {
      _isEmailValid = isValid;
    });
    return isValid;
  }

  Future<void> registerUser(String email, String password, String confirmPassword, BuildContext context) async {
    bool isEmailValid = _isValidEmail(email);

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || !isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua bidang')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi password tidak cocok')),
      );
      return;
    }

    final url = "http://192.168.1.12/Niceadmin/api/api_register_user.php";
    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendaftaran berhasil, silahkan login')),
          );
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(updateThemeMode: widget.updateThemeMode),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                var begin = Offset(-1.0, 0.0);
                var end = Offset.zero;
                var curve = Curves.ease;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftar: ${response.body}')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke server')),
      );
    }
  }

  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // Pengguna batal
      }

      // Gunakan informasi yang diperoleh dari Google untuk melakukan pendaftaran
      setState(() {
        email = googleUser.email;
        password = "GoogleAuth"; // Menggunakan penanda khusus karena password tidak ada
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pendaftaran berhasil dengan akun Google.")),
      );

      // Navigasi ke layar login atau beranda setelah pendaftaran
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return LoginScreen(updateThemeMode: widget.updateThemeMode);
      }));
    } catch (error) {
      print('Error saat mendaftar dengan Google: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal mendaftar dengan Google."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 238, 255),
                  Color.fromARGB(255, 0, 110, 255),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 60.0, left: 22),
              child: Stack(
                children: [
                  // Outline (bayangan hitam)
                  Text(
                    'Register',
                    style: GoogleFonts.lobster(
                      fontSize: 30,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..color = Colors.white,
                    ),
                  ),
                  // Teks utama (putih)
                  Text(
                    'Register',
                    style: GoogleFonts.lobster(
                      fontSize: 30,
                      color: Color.fromARGB(255, 6, 0, 31),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(1000),
                  topRight: Radius.circular(0),
                ),
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 142, 154, 156),
                    Color.fromARGB(255, 255, 255, 255),
                  ],
                ),
              ),
              height: double.infinity,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 20),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                        width: 150,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        cursorColor: Color.fromARGB(255, 0, 0, 0),
                        onChanged: (value) => email = value,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          prefixIcon: const Icon(Icons.email, color: Color.fromARGB(255, 0, 0, 0)),
                          suffixIcon: _isEmailValid ? Icon(Icons.check, color: Color.fromARGB(255, 0, 255, 8)) : Icon(Icons.check, color: Colors.red),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        cursorColor: Color.fromARGB(255, 0, 0, 0),
                        onChanged: (value) => password = value,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 0, 0, 0)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 236, 236, 236)),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        cursorColor: Color.fromARGB(255, 0, 0, 0),
                        onChanged: (value) => confirmPassword = value,
                        obscureText: !_isConfirmPasswordVisible,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 0, 0, 0)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          await registerUser(email, password, confirmPassword, context);
                        },
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 192, 26, 26),
                                  Color.fromARGB(255, 37, 26, 192),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                await registerUser(email, password, confirmPassword, context);
                              },
                              child: Container(
                                height: 55,
                                width: 400,
                                child: Center(
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 55,
                        width: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: TextButton.icon(
                          onPressed: _registerWithGoogle,
                          icon: Image.asset(
                            'assets/icons/google-symbol.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            'Daftar dengan Google',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Sudah memiliki akun?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 5),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(updateThemeMode: widget.updateThemeMode),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    var curve = Curves.easeInOut;

                                    var tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

                                    return FadeTransition(
                                      opacity: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 38, 0, 255),
                              ),
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
        ],
      ),
    );
  }
}
