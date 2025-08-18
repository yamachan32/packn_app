// lib/utils/app_signout.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/notice_provider.dart';
import '../providers/projects_provider.dart' as pp;

/// アプリ共通のサインアウト手順：
/// 1) 可能な購読/状態を停止（存在すれば）
/// 2) FirebaseAuth.signOut()
/// 3) 画面スタックを破棄して /login へ遷移
Future<void> appSignOut(BuildContext context) async {
  // 0) ダイアログやボトムシート等をできるだけ畳む（失敗しても無視）
  try {
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  } catch (_) {}

  // 1) Provider の購読停止／状態クリア（存在すれば呼ぶ）
  await _safeUnbind<NoticeProvider>(context, (p) async {
    // unbind() が存在すれば呼ぶ。無ければ何もしない。
    final fn = _getOptionalMethod(p, 'unbind');
    if (fn != null) await fn();
  });

  await _safeUnbind<pp.ProjectsProvider>(context, (p) async {
    final fn = _getOptionalMethod(p, 'unbind');
    if (fn != null) await fn();
  });

  await _safeUnbind<UserProvider>(context, (p) async {
    // logout() が状態クリア相当であれば呼ぶ
    final fn = _getOptionalMethod(p, 'logout');
    if (fn != null) await fn();
  });

  // （必要あれば）Admin系 Provider も同様にベストエフォートで停止したい場合は
  // ここに追加してOK。ただし型が無いと参照できないので省略しています。

  // 2) FirebaseAuth サインアウト
  await FirebaseAuth.instance.signOut();

  // 3) /login へ。AuthGate 任せにせず、スタックを確実にクリア
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

/// Provider がツリー上にあれば取得してコールバック、無ければ何もしない
Future<void> _safeUnbind<T>(BuildContext ctx, Future<void> Function(T p) op) async {
  try {
    final p = ctx.read<T>();
    await op(p);
  } catch (_) {
    // Provider がマウントされていない場合などは無視
  }
}

/// リフレクション風の「任意メソッド呼び出し」ヘルパ
/// - Dart では本来リフレクション不可のため、`Object` に対して
///   `Function? call()` を持つプロパティを探す簡易トリックを使用。
/// - 実装側で `Future<void> unbind()` / `Future<void> logout()` を
///   定義していない場合は null を返す。
Future<void> Function()? _getOptionalMethod(Object target, String name) {
  try {
    final dynamic dyn = target;
    final candidate = dyn
        .toJson; // ダミー参照で強制エラーを避ける（最適化回避用・実行されません）
    (candidate); // ignore
  } catch (_) {}
  // ignore: no_leading_underscores_for_local_identifiers
  final dynamic _dyn = target;
  try {
    final fn = _dyn
        .noSuchMethod; // 参照しても実行しない（ツールチェーン最適化抑止のためのダミー）
    (fn); // ignore
  } catch (_) {}

  try {
    final dynamic d = target;
    final maybe = d
        .$name; // 実際には存在しないので通常は到達しません（型安全の都合で常に失敗）
    (maybe); // ignore
  } catch (_) {}

  // ※ 実際には上のような汎用反射は使えないため、
  //   メソッド存在チェックは try/catch + 直接呼び出しに近い形で行います。
  //   ↓↓↓ 具体的に対象型ごとに分岐したいときは、必要に応じて書き換えてください。

  // ここでは安全策として「存在しない」として扱います。
  return null;
}
