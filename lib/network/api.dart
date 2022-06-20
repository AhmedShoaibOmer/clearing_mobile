import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Network {
  Uri getUrl(path, query) => Uri(
      scheme: 'http',
      host: '192.168.43.253',
      port: 8000,
      path: path,
      query: query);

  var token;

  Future<void> _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    token = localStorage.getString('token');
    print('Restored token : $token');
  }

  Future<http.Response?> login(data) async {
    return _auth(data, 'client/login');
  }

  Future<http.Response?> _auth(data, apiURL) async {
    try {
      print(getUrl(apiURL,
              'email=${Uri.encodeQueryComponent(data['email'], encoding: latin1)}&password=${data['password']}')
          .toString());
      String body = jsonEncode(data);
      print('json body : $body');
      http.Response res = await http.post(
        getUrl(
          apiURL,
          'email=${Uri.encodeQueryComponent(data['email'], encoding: latin1)}&password=${data['password']}',
        ),
        /*body: body,*/ headers: _setHeaders(),
      );
      print(res.request?.url.toString());
      print('response body : ' + res.body.toString());
      return res;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<http.Response> issueCheque(data) async {
    return await http.post(
        getUrl(
            'client/issue/cheque',
            'amount=${Uri.encodeQueryComponent(data['amount'])}&'
                'clientaccount_id_from=${Uri.encodeQueryComponent(data['clientaccount_id_from'])}&'
                'clientaccount_id_to=${Uri.encodeQueryComponent(data['clientaccount_id_to'])}&'
                'bankaccount_id_from=${Uri.encodeQueryComponent(data['bankaccount_id_from'])}&'
                'bankaccount_id_to=${Uri.encodeQueryComponent(data['bankaccount_id_to'])}&'
                'image=${Uri.encodeQueryComponent(data['image'])}'),
        /*body: jsonEncode(data),*/ headers: _setHeaders());
  }

  Future<http.Response> getUser(String? id) {
    return getData('client/getAccount/$id');
  }

  Future<http.Response> getData(apiURL) async {
    await _getToken();
    return await http.get(
      getUrl(apiURL, null),
      headers: _setHeaders(),
    );
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
