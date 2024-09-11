import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jpr/forgot_password/forgot_password_screen.dart';
import 'package:jpr/regScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jpr/page/home/HomePage.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  final Function(ThemeMode) updateThemeMode;

  const LoginScreen({Key? key, required this.updateThemeMode}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  bool _isEmailValid = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Inisialisasi GoogleSignIn

  @override
  void initState() {
    super.initState();
    _checkLoggedInStatus();
  }

  // Mengecek apakah pengguna sudah login sebelumnya
  void _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // Navigasi ke home page jika sudah login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(updateThemeMode: widget.updateThemeMode)),
      );
    }
  }

  // Validasi email menggunakan regex
  bool _isValidEmail(String email) {
    String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(emailPattern);
    return regex.hasMatch(email);
  }

  // Fungsi untuk login menggunakan Google Sign-In (Firebase)
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User batal login
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Gunakan kredensial Google untuk autentikasi Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Login ke Firebase dengan kredensial Google
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Simpan email ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', googleUser.email);
      await prefs.setBool('isLoggedIn', true);

      // Kirim email ke server untuk disimpan di database
      String apiURL = "http://192.168.1.12/Niceadmin/api/api_login_user.php";
      var response = await http.post(
        Uri.parse(apiURL),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': googleUser.email, // Kirim hanya email tanpa password
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success']) {
          // Simpan ID pengguna yang diterima dari API
          if (data['pelanggan_id'] != null) {
            await prefs.setInt('pelanggan_id', data['pelanggan_id']);
          }

          // Navigasi ke halaman beranda setelah login berhasil
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
            return HomePage(updateThemeMode: widget.updateThemeMode);
          }));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal terhubung ke server: ${response.statusCode}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      print('Error saat login dengan Google: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal login dengan Google."),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Fungsi untuk login manual menggunakan email dan password
  Future<void> login(BuildContext context, String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Email dan password harus diisi."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Email tidak valid."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String baseURL = "http://192.168.1.18/Niceadmin/api/api_login_user.php";

    try {
      var response = await http.post(
        Uri.parse(baseURL),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success']) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setBool('isLoggedIn', true);

          if (data['pelanggan_id'] != null) {
            await prefs.setInt('pelanggan_id', data['pelanggan_id']);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return HomePage(updateThemeMode: widget.updateThemeMode);
            }));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("ID pelanggan tidak valid."),
              backgroundColor: Colors.red,
            ));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal terhubung ke server: ${response.statusCode}"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Terjadi kesalahan. Coba lagi nanti."),
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
                  Text(
                    'Login',
                    style: GoogleFonts.lobster(
                      fontSize: 30,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..color = Colors.white,
                    ),
                  ),
                  Text(
                    'Login',
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
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 150,
                        width: 150,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        cursorColor: Color.fromARGB(255, 0, 0, 0),
                        controller: emailController,
                        onChanged: (value) {
                          setState(() {
                            _isEmailValid = _isValidEmail(value);
                          });
                        },
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          suffixIcon: _isEmailValid
                              ? Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.check, color: Colors.red),
                          prefixIcon: Icon(Icons.email, color: Color.fromARGB(255, 0, 0, 0)),
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Color.fromARGB(255, 0, 0, 0),
                        controller: passwordController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility : Icons.visibility_off,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          prefixIcon: Icon(Icons.lock, color: Color.fromARGB(255, 0, 0, 0)),
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color.fromARGB(255, 236, 236, 236)),
                          ),
                        ),
                        obscureText: _isObscure,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return ForgotPasswordScreen();
                                },
                              ),
                            );
                          },
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 38, 0, 255),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        height: 55,
                        width: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 192, 26, 26),
                              Color.fromARGB(255, 37, 26, 192),
                            ],
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            login(context, emailController.text, passwordController.text);
                          },
                          child: const Center(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 55,
                        width: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: TextButton.icon(
                          onPressed: _loginWithGoogle,
                          icon: Image.asset(
                            'assets/icons/google-symbol.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            'Login dengan Google',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Belum memiliki akun?",
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
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      RegScreen(updateThemeMode: widget.updateThemeMode),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Text(
                              "Register",
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
