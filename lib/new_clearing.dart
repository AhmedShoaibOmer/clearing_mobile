import 'dart:async';
import 'dart:convert';

import 'package:clearing_mobile/network/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fast_forms/flutter_fast_forms.dart';
import 'package:internet_checker_banner/internet_checker_banner.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class NewClearing extends StatefulWidget {
  const NewClearing({Key? key}) : super(key: key);

  @override
  State<NewClearing> createState() => _NewClearingState();
}

class _NewClearingState extends State<NewClearing> {
  final _formKey = GlobalKey<FormState>();

  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  String? amount;

  String? clientIdTo;

  String? image;

  String? bankIdTo;

  String? clientIdFrom;

  String? bankIdFrom;

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

  void _sendInformation() async {
    _formKey.currentState?.validate();
    bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      _showMsg("قم بإصلاح جميع الأخطاء");
    } else {
      if (!isConnected) {
        _showMsg("لا يوجد إتصال إنترنت");
      } else {
        if (await _checkUser(clientIdFrom)) {
          if (await _checkUser(clientIdTo)) {
            var data = {
              'amount': amount,
              'clientaccount_id_from': clientIdFrom,
              'clientaccount_id_to': clientIdTo,
              'bankaccount_id_from': bankIdFrom,
              'bankaccount_id_to': bankIdTo,
              'image': image,
            };

            var res = await Network().issueCheque(data);
            if (res == null) {
              _btnController.error();
              _showMsg('حدث خطأ ما, جرب مرة أخرى');
            } else {
              var body = json.decode(res.body);
              if (body['success']) {
                _btnController.success();

                _showMsg(body['تمت العملية بنجاح']);
              } else {
                _btnController.error();
                _showMsg(body['message']);
              }
            }
          } else {
            _showMsg('رقم الحساب المرسل إليه غير صحيح');
          }
        } else {
          _showMsg('رقم الحساب المرسل منه غير صحيح');
        }
      }
    }
    _btnController.reset();
  }

  Future<bool> _checkUser(String? id) async {
    var res = await Network().getUser(id);
    if (res == null) {
      _btnController.error();
      _showMsg('حدث خطأ ما, جرب مرة أخرى');
      return false;
    } else {
      var body = json.decode(res.body);
      if (body['success']) {
        return true;
      } else {
        _btnController.error();
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقاصة جديدة'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  top: 32.0,
                  bottom: 56,
                  right: 56,
                  left: 56,
                ),
                child: Text(
                  'New Clearing',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              FastForm(
                formKey: _formKey,
                children: _buildForm(context),
                onChanged: (value) {
                  // ignore: avoid_print
                  print('Form changed: ${value.toString()}');

                  amount = value['amount'];
                  clientIdTo = value['clientaccount_id_to'];
                  clientIdFrom = value['clientaccount_id_from'];
                  bankIdTo = value['bankaccount_id_to'];
                  bankIdFrom = value['bankaccount_id_from'];
                  image = value['image'];

                  _btnController.reset();
                },
              ),
              RoundedLoadingButton(
                child: Text('إرسال البيانات',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )),
                controller: _btnController,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _sendInformation(),
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
                child: const Text('تفريغ الحقول؟'),
                onPressed: () {
                  _formKey.currentState?.reset();
                  _btnController.reset();
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
            name: 'clientaccount_id_to',
            labelText: 'رقم حساب المستفيد',
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          FastTextField(
            name: 'clientaccount_id_from',
            labelText: 'رقم الحساب المرسل منه',
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          FastTextField(
            name: 'amount',
            labelText: 'المبلغ المرفق',
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          FastTextField(
            name: 'bankaccount_id_from',
            labelText: 'رقم البنك المرسل منه',
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          FastTextField(
            name: 'bankaccount_id_to',
            labelText: ' البنك المرسل اليه',
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
          FastTextField(
            name: 'image',
            labelText: 'ارفاق صورة لشيك',
            inputFormatters: const [],
            validator: Validators.compose([
              Validators.required((value) => 'الحقل مطلوب'),
            ]),
          ),
        ],
      ),
    ];
  }
}
