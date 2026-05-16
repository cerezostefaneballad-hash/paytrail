import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/student.dart';

class ApiService {
  String? _token;
  void setToken(String? t) => _token = t;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  dynamic _handle(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? null : jsonDecode(r.body);
    }
    throw Exception(r.body);
  }

  Future<Map<String, dynamic>> login(String u, String p) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: _headers,
      body: jsonEncode({'username': u, 'password': p}),
    );
    return _handle(r);
  }

  Future<void> logout() async {
    await http.post(Uri.parse('${ApiConfig.baseUrl}/logout'), headers: _headers);
    _token = null;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/dashboard'), headers: _headers);
    return Map<String, dynamic>.from(_handle(r));
  }

  Future<List<Student>> getStudents({String? year, String? search}) async {
    final qs = <String, String>{};
    if (year != null && year.isNotEmpty) qs['year'] = year;
    if (search != null && search.isNotEmpty) qs['search'] = search;
    final uri = Uri.parse('${ApiConfig.baseUrl}/students').replace(queryParameters: qs);
    final r = await http.get(uri, headers: _headers);
    final List data = _handle(r);
    return data.map((j) => Student.fromJson(j)).toList();
  }

  Future<Student> createStudent(Student s) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/students'),
      headers: _headers,
      body: jsonEncode(s.toJson()),
    );
    return Student.fromJson(_handle(r));
  }

  Future<Student> updateStudent(int id, Student s) async {
    final r = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/students/$id'),
      headers: _headers,
      body: jsonEncode(s.toJson()),
    );
    return Student.fromJson(_handle(r));
  }

  Future<void> deleteStudent(int id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/students/$id'), headers: _headers);
  }
}