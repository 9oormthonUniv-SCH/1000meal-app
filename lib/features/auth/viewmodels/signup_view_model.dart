import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/role.dart';
import '../models/signup_models.dart';
import '../repositories/auth_repository.dart';

class SignupDraft {
  final String? id;
  final String? name;
  final String? email;
  final String? password;
  final bool? agreeTos;
  final bool? agreePrivacy;

  const SignupDraft({
    this.id,
    this.name,
    this.email,
    this.password,
    this.agreeTos,
    this.agreePrivacy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'agreeTos': agreeTos,
        'agreePrivacy': agreePrivacy,
      };

  factory SignupDraft.fromJson(Map<String, dynamic> json) {
    return SignupDraft(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      password: json['password']?.toString(),
      agreeTos: json['agreeTos'] == true,
      agreePrivacy: json['agreePrivacy'] == true,
    );
  }
}

class SignupViewModel extends ChangeNotifier {
  SignupViewModel(this._repo);

  static const _draftKey = 'signup_draft_v1';

  final AuthRepository _repo;

  // Step1: ID
  String id = '';
  bool checkingId = false;
  bool? idOk;
  String? idErrorMessage;

  // Step2/3: credentials
  String name = '';
  String pw = '';
  String pw2 = '';
  String email = '';

  bool agreeTos = false;
  bool agreePrivacy = false;

  // email verification
  bool emailSent = false;
  String emailCode = '';
  bool verified = false;
  bool sendingEmail = false;
  bool verifyingEmail = false;
  String? emailError;

  bool submitting = false;
  String? submitError;

  // 요구사항: 8~16자, 영문/숫자/특수문자 모두 포함(공백 불가)
  final RegExp pwdRule = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*().,_-])[A-Za-z\d!@#$%^&*().,_-]{8,16}$',
  );

  bool get validPwd => pwdRule.hasMatch(pw) && !pw.contains(RegExp(r'\s'));
  bool get samePwd => pw.isNotEmpty && pw == pw2;

  bool get validEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) && email.trim().endsWith('@sch.ac.kr');

  bool get canNextFromId => idOk == true && !checkingId;

  bool get canSubmit =>
      name.trim().isNotEmpty &&
      validPwd &&
      samePwd &&
      validEmail &&
      verified &&
      agreeTos &&
      agreePrivacy;

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final d = SignupDraft.fromJson(json);
      if (d.id != null) id = d.id!;
      name = d.name ?? name;
      email = d.email ?? email;
      pw = d.password ?? pw;
      pw2 = d.password ?? pw2;
      agreeTos = d.agreeTos ?? agreeTos;
      agreePrivacy = d.agreePrivacy ?? agreePrivacy;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = SignupDraft(
      id: id.isEmpty ? null : id,
      name: name.isEmpty ? null : name,
      email: email.isEmpty ? null : email,
      password: pw.isEmpty ? null : pw,
      agreeTos: agreeTos,
      agreePrivacy: agreePrivacy,
    );
    await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> onChangeId(String v) async {
    id = v;
    idOk = null;
    idErrorMessage = null;
    notifyListeners();

    if (RegExp(r'^.{8}$').hasMatch(v)) {
      checkingId = true;
      notifyListeners();
      try {
        final res = await _repo.verifyId(v);
        idOk = res.valid;
        if (!res.valid) idErrorMessage = res.message;
      } catch (e) {
        idOk = false;
        idErrorMessage = '아이디 확인 중 오류가 발생했습니다.';
      } finally {
        checkingId = false;
        notifyListeners();
      }
    }
  }

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setPw(String v) {
    pw = v;
    notifyListeners();
  }

  void setPw2(String v) {
    pw2 = v;
    notifyListeners();
  }

  void setEmail(String v) {
    email = v;
    // 이메일 바뀌면 인증 상태 초기화(웹 동작과 동일)
    verified = false;
    emailSent = false;
    emailCode = '';
    emailError = null;
    notifyListeners();
  }

  void setAgreeTos(bool v) {
    agreeTos = v;
    notifyListeners();
  }

  void setAgreePrivacy(bool v) {
    agreePrivacy = v;
    notifyListeners();
  }

  void setAgreeAll(bool v) {
    agreeTos = v;
    agreePrivacy = v;
    notifyListeners();
  }

  void setEmailCode(String v) {
    emailCode = v;
    notifyListeners();
  }

  Future<void> sendEmail() async {
    if (!validEmail) {
      emailError = '이메일은 @sch.ac.kr 형식이어야 합니다.';
      notifyListeners();
      return;
    }

    sendingEmail = true;
    emailError = null;
    notifyListeners();

    try {
      final alreadyRegistered = await _repo.getSignupEmailStatus(email);
      if (alreadyRegistered) {
        emailError = '이미 가입된 이메일입니다.';
        return;
      }

      emailSent = false;
      emailCode = '';
      verified = false;

      await _repo.sendEmailVerification(email);
      emailSent = true;
    } catch (e) {
      if (e is ApiException) {
        emailError = mapErrorToMessage(e, responseData: e.details);
      } else {
        emailError = '메일 발송 실패';
      }
    } finally {
      sendingEmail = false;
      notifyListeners();
    }
  }

  Future<void> verifyEmailCode() async {
    if (!emailSent) return;
    if (emailCode.trim().isEmpty) return;

    verifyingEmail = true;
    emailError = null;
    notifyListeners();

    try {
      await _repo.verifyEmail(email: email, code: emailCode.trim());
      verified = true;
      await saveDraft();
    } catch (e) {
      verified = false;
      if (e is ApiException) {
        emailError = mapErrorToMessage(e, responseData: e.details);
      } else {
        emailError = '인증 실패';
      }
    } finally {
      verifyingEmail = false;
      notifyListeners();
    }
  }

  Future<bool> submit() async {
    if (!canSubmit) return false;

    submitting = true;
    submitError = null;
    notifyListeners();

    try {
      await _repo.signUp(
        SignUpRequest(
          role: Role.student,
          userId: id,
          name: name.trim(),
          email: email.trim(),
          password: pw,
        ),
      );
      await clearDraft();
      return true;
    } catch (e) {
      if (e is ApiException) {
        submitError = mapErrorToMessage(e, responseData: e.details);
      } else {
        submitError = '회원가입 실패';
      }
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}


