import 'package:clearing_mobile/new_clearing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fast_forms/flutter_fast_forms.dart';
import 'package:http/http.dart';
import 'package:internet_checker_banner/internet_checker_banner.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'network/api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String? email, password;
  bool? rememberMe = false;

  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    InternetCheckerBanner().initialize(
      context,
      title: "لا يوجد إتصال إنترنت",
    );
    InternetConnectionChecker().onStatusChange.listen((event) {
      if (event == InternetConnectionStatus.connected) {
        if (mounted) {
          setState(() {
            isConnected = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isConnected = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    InternetCheckerBanner().dispose();
    super.dispose();
  }

  _showMsg(msg) {
    if (kDebugMode) {
      print(msg);
    }
    final snackBar = SnackBar(
      content: Text(msg),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _login() async {
    bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      _showMsg("قم بإصلاح جميع الأخطاء");
    } else {
      if (!isConnected) {
        _showMsg("لا يوجد إتصال إنترنت");
      } else {
        var data = {'email': email, 'password': password};
        print('Data Object: $data');
        Response? res = await Network().login(data);
        if (res == null) {
          _btnController.error();
          print('Response equals null');
          _showMsg('حدث خطأ ما, جرب مرة أخرى');
        } else {
          var body = json.decode(res.body);
          if (body['success']) {
            _btnController.success();
            SharedPreferences localStorage =
                await SharedPreferences.getInstance();
            localStorage.setString('token', json.encode(body['token']));
            localStorage.setString('user', json.encode(body['user']));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewClearing(),
              ),
            );
          } else {
            _btnController.error();
            _showMsg(body['message']);
          }
        }
      }
    }
    _btnController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  top: 32.0,
                  bottom: 56,
                  right: 56,
                  left: 56,
                ),
                child: Text(
                  'Clearing',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              FastForm(
                formKey: _formKey,
                children: _buildForm(context),
                onChanged: (value) {
                  // ignore: avoid_print
                  print('Form changed: ${value.toString()}');
                  email = value['email'];
                  password = value['password'];
                  rememberMe = value['rememberMe'];
                  _btnController.reset();
                },
              ),
              RoundedLoadingButton(
                child: Text('دخول',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )),
                controller: _btnController,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _login(),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Colors.black,
                    width: 100,
                    height: 2,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Text(
                    'أو',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    color: Colors.black,
                    width: 100,
                    height: 2,
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              TextButton(
                child: const Text('إغلاق التطبيق؟'),
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForm(BuildContext context) {
    return [
      FastFormSection(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
        children: [
          FastTextField(
            name: 'email',
            labelText: 'إيميل المستخدم',
            prefix: const Icon(Icons.person),
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          FastTextField(
            name: 'password',
            labelText: 'كلمة المرور',
            prefix: const Icon(Icons.lock),
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          const FastCheckbox(
            name: 'remember_me',
            decoration: InputDecoration(border: InputBorder.none),
            titleText: 'حفظ الدخول',
            contentPadding: EdgeInsets.fromLTRB(12.0, 0, 0, 0),
          ),
        ],
      ),
    ];
  }
}
