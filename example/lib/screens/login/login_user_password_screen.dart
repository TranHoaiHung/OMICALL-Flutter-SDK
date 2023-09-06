import 'dart:async';
import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../dial/Dial_Screen_2.dart';
import '../dial/dial_screen.dart';
import '../video_call/video_call_screen.dart';

import '../call_home/call_home_screen.dart';
import '../choose_type_ui/choose_type_ui_screen.dart';

class LoginUserPasswordScreen extends StatefulWidget {
  const LoginUserPasswordScreen({Key? key}) : super(key: key);

  // var phoneNumber = "";
  @override
  State<LoginUserPasswordScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginUserPasswordScreen> {
  // NSString * USER_NAME1 = @"100";
  // NSString * PASS_WORD1 = @"Kunkun";
  // NSString * USER_NAME2 = @"101";
  // NSString * PASS_WORD2 = @"Kunkun12345";
  //video
  late final TextEditingController _userNameController = TextEditingController()
    ..text = Platform.isIOS ? '101' : '101';
  late final TextEditingController _passwordController = TextEditingController()
    ..text = Platform.isIOS ? 'M1zx7YyK30' : 'M1zx7YyK30';
  late final TextEditingController _serviceUrlController =
      TextEditingController()..text = 'hungth12';
  late final TextEditingController _hostUrlController = TextEditingController()
    ..text = 'vh.omicrm.com';

  bool _supportVideoCall = true;

  bool _isVideoCall = false;
  late StreamSubscription _subscription;
  GlobalKey<DialScreenState>? _dialScreenKey;
  GlobalKey<VideoCallState>? _videoScreenKey;
  TextStyle basicStyle = const TextStyle(
    color: Colors.white,
    fontSize: 16,
  );



  // Initially password is obscure
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    OmicallClient.instance.getCurrentUser().then((value) {
      debugPrint(value?.toString());
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _serviceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(
      String text,
      IconData? icon, {
      bool isPass = false,
    }) {
      return InputDecoration(
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : const SizedBox.shrink(),
        labelText: text,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        hintText: text,
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          size: MediaQuery.of(context).size.width * 0.06,
          color: Colors.grey,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.01),
          ),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: BorderSide(
            color: Colors.red,
            width: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 225, 121, 243),
            width: MediaQuery.of(context).size.width * 0.008,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Image.asset(
              "assets/images/signIn01.png",
              width: MediaQuery.of(context).size.width * 0.9,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              "assets/images/signIn02.png",
              height: MediaQuery.of(context).size.height * 0.28,
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                const Text(
                  "OMICALL",
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                const Text(
                  "Sign in to your account",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.07,
                ),
                Form(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          child: TextFormField(
                            controller: _userNameController,
                            keyboardType: TextInputType.number,
                            decoration:
                                inputDecoration('User Name', Icons.person),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This field cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: inputDecoration('Password', Icons.lock,
                                isPass: true),
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This field cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          child: TextFormField(
                            controller: _serviceUrlController,
                            decoration: inputDecoration(
                                'Service', Icons.cleaning_services),
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This field cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          child: TextFormField(
                            controller: _hostUrlController,
                            decoration:
                                inputDecoration("Host", Icons.location_city),
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This field cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _supportVideoCall = !_supportVideoCall;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    _supportVideoCall
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 24,
                                    color: _supportVideoCall
                                        ? const Color.fromARGB(
                                            255, 225, 121, 243)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    "Video call",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _supportVideoCall
                                          ? const Color.fromARGB(
                                              255, 225, 121, 243)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              "Forget you password",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              "Sign in",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03,
                            ),
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.height * 0.1,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  _login();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 255, 230, 85),
                                        Color.fromARGB(255, 176, 74, 166),
                                      ], // Define your gradient colors
                                      begin: Alignment
                                          .bottomRight, // Define the starting point of the gradient
                                      end: Alignment
                                          .topLeft, // Define the ending point of the gradient
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.height * 0.1,
                                    ),
                                  ),
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
                                  child:
                                      const Icon(Icons.navigate_next_rounded),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Create",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationThickness: 2.0,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 68),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.all(
                    Radius.circular(MediaQuery.of(context).size.width * 0.1),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _login() async {
    if (_userNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _serviceUrlController.text.isEmpty ||
        _serviceUrlController.text.isEmpty ||
        _hostUrlController.text.isEmpty) {
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return ChooseTypeUIScreen(
        userName: _userNameController.text,
        password: _passwordController.text,
        realm: _serviceUrlController.text,
        host: _hostUrlController.text,
        usrUuid: '',
        apiKey: '',
        isVideo: _supportVideoCall,
      );
    }));
  }
}
