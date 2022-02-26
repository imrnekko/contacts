import 'package:cloud_firestore/cloud_firestore.dart';

class UserContacts {
  String? user;
  String? phone;
  DateTime? checkin;

  UserContacts({this.user, this.phone, this.checkin});
}
