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

  // ===== AUTH =====

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

  // ===== DASHBOARD =====

  Future<Map<String, dynamic>> dashboard() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/dashboard'), headers: _headers);
    return Map<String, dynamic>.from(_handle(r));
  }

  // ===== STUDENTS =====

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

  // ===== ADMIN USERS =====

  Future<List<Map<String, dynamic>>> getAdmins() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/admins'), headers: _headers);
    final List data = _handle(r);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAdmin(String username, String fullName, String password) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admins'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'full_name': fullName,
        'password': password,
      }),
    );
    return Map<String, dynamic>.from(_handle(r));
  }

  Future<Map<String, dynamic>> updateAdmin(int id, String username, String fullName, String? password) async {
    final body = <String, dynamic>{
      'username': username,
      'full_name': fullName,
    };
    if (password != null && password.isNotEmpty) body['password'] = password;
    final r = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admins/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return Map<String, dynamic>.from(_handle(r));
  }

  Future<void> deleteAdmin(int id) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}/admins/$id'), headers: _headers);
  }

  // ===== SETTINGS =====

  Future<Map<String, dynamic>?> getSettings() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/settings'), headers: _headers);
    final data = _handle(r);
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> saveSettings(String acadYear, String semester, double fee) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/settings'),
      headers: _headers,
      body: jsonEncode({
        'acad_year': acadYear,
        'semester': semester,
        'semestral_fee': fee,
      }),
    );
    return Map<String, dynamic>.from(_handle(r));
  }

  // ===== SEMESTER REPORT =====
  Future<Map<String, dynamic>> getSemesterReport({String? academicYear, String? semester}) async {
    final queryParams = <String, String>{};
    if (academicYear != null && academicYear.isNotEmpty) {
      queryParams['academic_year'] = academicYear;
    }
    if (semester != null && semester.isNotEmpty) {
      queryParams['semester'] = semester;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/semester-report')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);
    final result = _handle(response);

    if (result == null) {
      return {};
    }
    return Map<String, dynamic>.from(result as Map);
  }
}