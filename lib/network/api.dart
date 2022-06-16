import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Network {
  Uri getUrl(path) => Uri.http('192.168.43.253:8000', path);

  var token;

  _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    token = jsonDecode(localStorage.getString('token')!)['token'];
  }

  login(data) {
    _auth(data, 'client/login');
  }

  _auth(data, apiURL) async {
    try {
      print(getUrl(apiURL).toString());
      return await http.post(getUrl(apiURL),
          body: jsonEncode(data), headers: _setHeaders());
    } catch (e) {
      print(e);
    }
  }

  issueCheque(data) async {
    return await http.post(getUrl('client/issue/cheque'),
        body: jsonEncode(data), headers: _setHeaders());
  }

  getUser(String? id) {
    return getData('client/getAccount/$id');
  }

  getData(apiURL) async {
    await _getToken();
    return await http.get(
      getUrl(apiURL),
      headers: _setHeaders(),
    );
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
