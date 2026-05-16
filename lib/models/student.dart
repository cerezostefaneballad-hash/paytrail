class Student {
  final int? id;
  final String studentId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String yearLevel;
  final double firstAmount;
  final String? firstDate;
  final double secondAmount;
  final String? secondDate;
  final double thirdAmount;
  final String? thirdDate;
  final double balance;
  final String status;
  final String? issuedBy;

  Student({
    this.id,
    required this.studentId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.yearLevel,
    this.firstAmount = 0,
    this.firstDate,
    this.secondAmount = 0,
    this.secondDate,
    this.thirdAmount = 0,
    this.thirdDate,
    this.balance = 0,
    this.status = 'Unpaid',
    this.issuedBy,
  });

  String get fullName =>
      '$lastName, $firstName ${middleName ?? ''}'.trim();

  factory Student.fromJson(Map<String, dynamic> j) => Student(
    id: j['id'],
    studentId: j['student_id'] ?? '',
    firstName: j['first_name'] ?? '',
    middleName: j['middle_name'],
    lastName: j['last_name'] ?? '',
    yearLevel: j['year_level']?.toString() ?? '',
    firstAmount: double.tryParse('${j['first_amount'] ?? 0}') ?? 0,
    firstDate: j['first_date'],
    secondAmount: double.tryParse('${j['second_amount'] ?? 0}') ?? 0,
    secondDate: j['second_date'],
    thirdAmount: double.tryParse('${j['third_amount'] ?? 0}') ?? 0,
    thirdDate: j['third_date'],
    balance: double.tryParse('${j['balance'] ?? 0}') ?? 0,
    status: j['status'] ?? 'Unpaid',
    issuedBy: j['issued_by'],
  );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'year_level': yearLevel,
    'first_amount': firstAmount,
    'first_date': firstDate,
    'second_amount': secondAmount,
    'second_date': secondDate,
    'third_amount': thirdAmount,
    'third_date': thirdDate,
  };
}