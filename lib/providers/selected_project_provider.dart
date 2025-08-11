import 'package:flutter/material.dart';

/// 画面横断で「選択中プロジェクトID」を保持するProvider。
/// Home以外（お知らせ・管理画面など）からも参照できます。
class SelectedProjectProvider extends ChangeNotifier {
  String? _id;
  String? get id => _id;

  void setId(String? id) {
    _id = id;
    notifyListeners();
  }
}
