import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Quản lý âm thanh trong game Caro
class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  /// Phát âm thanh khi đánh quân cờ
  static Future<void> playMove() async {
    try {
      await _player.stop(); // Dừng âm thanh đang phát trước đó (nếu có) để giảm độ trễ
      await _player.play(AssetSource('sounds/move.wav'));
    } catch (e) {
      debugPrint('Lỗi phát âm thanh move: $e');
    }
  }

  /// Phát âm thanh khi thắng cuộc
  static Future<void> playWin() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/win.wav'));
    } catch (e) {
      debugPrint('Lỗi phát âm thanh win: $e');
    }
  }

  /// Phát âm thanh khi hòa cờ
  static Future<void> playDraw() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/draw.wav'));
    } catch (e) {
      debugPrint('Lỗi phát âm thanh draw: $e');
    }
  }
}
