import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Users {

  // THIS CLASS WAS PREVIOUSLY User{}, but due to the firebase new package update, which uses User class instead of FirebaseUser, this class has been renamed to Users

  final String uid;

  Users({this.uid});
  UserData userData = UserData();
}

class UserData {
  String email;
  String displayName;
  String gender;
  String block;
  String bio;
  String dp;
  String nickname;
  bool isAnonymous;
  String anonBio;
  String anonInterest;
  String anonDp;
  int fame;
  String media;
  String course;
  String playlist;
  String accoms;

  UserData(
      {this.email,
        this.displayName,
        this.nickname,
        this.gender,
        this.block,
        this.bio,
        this.dp,
        this.isAnonymous,
        this.anonBio,
        this.anonInterest,
        this.anonDp,
        this.fame,
        this.media,
        this.course,
        this.playlist,
        this.accoms});

  UserData.fromMap(Map<String, dynamic> data) {
    email = data['email'];
    displayName = data['name'];
    nickname = data['nickname'];
    gender = data['gender'];
    block = data['block'];
    bio = data['bio'];
    dp = data['dp'];
    isAnonymous = data['isAnonymous'];
    anonBio = data['anonBio'];
    anonInterest = data['anonInterest'];
    anonDp = data['anonDp'];
    fame = data['fame'];
  }
  getUserData(ProfileNotifier profileNotifier) async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection("users").get();
    List<UserData> _profileList = [];
    snapshot.docs.forEach((doc) {
      UserData data = UserData.fromMap(doc.data());
      _profileList.add(data);
    });

    profileNotifier.profileList = _profileList;
  }
}

class ProfileNotifier with ChangeNotifier {
  List<UserData> _profileList = [];
  UserData _currentProfile;

  UnmodifiableListView<UserData> get profileList =>
      UnmodifiableListView(_profileList);

  UserData get currentProfile => _currentProfile;

  set profileList(List<UserData> profileList) {
    _profileList = profileList;
    notifyListeners();
  }

  set currentProfile(UserData profile) {
    _currentProfile = profile;
    notifyListeners();
  }
}
