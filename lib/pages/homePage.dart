import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _initialPosition = LatLng(35.6812, 139.7671); // 東京駅付近
  final MapController _mapController = MapController();
  LatLng? _currentPosition; // 現在地を保存する変数を追加
  final List<Map<String, dynamic>> _otherUsersData = [
    {
      'position': LatLng(35.6822, 139.7671),
      'username': 'ユーザーA',
      'bikeName': 'バイクA',
      'imageUrl': 'assets/hayabusa.jpg'
    },
    {
      'position': LatLng(35.6832, 240.7671),
      'username': 'ユーザーB',
      'bikeName': 'バイクB',
      'imageUrl': 'https://example.com/imageB.jpg'
    },
  ]; // 他のユーザーのデータを保存するリストを追加
  String? _sentMessage; // 送信されたメッセージを保存する変数を追加
  Timer? _messageTimer; // タイマーを追加

  Future<void> _moveToCurrentLocation() async {
    try {
      // 位置情報の権限を確認
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // ユーザーに通知
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('位置情報の権限が必要です')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 永久に拒否された場合
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定から位置情報の権限を許可してください')),
        );
        return;
      }

      // 位置情報サービスが有効か確認
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('位置情報サービスを有効にしてください')),
        );
        return;
      }

      // 現在位置を取得
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition =
            LatLng(position.latitude, position.longitude); // 現在地を保存
      });
      _mapController.move(
        _currentPosition!,
        15.0,
      );

      // 近くに他のユーザーがいるか確認
      for (var userData in _otherUsersData) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          userData['position'].latitude,
          userData['position'].longitude,
        );

        if (distance < 1000.0) {
          // 100メートル以内に他のユーザーがいる場合
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String _selectedMessage = 'こんにちは！'; // 定型文の初期値
              List<String> _presetMessages = [
                'こんにちは！',
                '近くにいますね！',
                '一緒に走りませんか？',
              ]; // 定型文のリスト

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    title: const Text('近くに他のユーザーがいます！'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        userData['imageUrl'].startsWith('assets')
                            ? Image.asset(
                                userData['imageUrl'],
                                errorBuilder: (BuildContext context,
                                    Object error, StackTrace? stackTrace) {
                                  return const Icon(Icons.error);
                                },
                              )
                            : Image.network(
                                userData['imageUrl'],
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  } else {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                (loadingProgress
                                                        .expectedTotalBytes ??
                                                    1)
                                            : null,
                                      ),
                                    );
                                  }
                                },
                                errorBuilder: (BuildContext context,
                                    Object error, StackTrace? stackTrace) {
                                  return const Icon(Icons.error);
                                },
                              ),
                        const SizedBox(height: 10),
                        Text('ユーザー名: ${userData['username']}'),
                        Text('バイク名: ${userData['bikeName']}'),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _selectedMessage,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _selectedMessage = newValue;
                              setState(() {
                                _selectedMessage = newValue;
                              });
                            }
                          },
                          items: _presetMessages
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('送信'),
                        onPressed: () {
                          // 状態更新のメソッドを呼び出す
                          _sendMessage(_selectedMessage);
                          print('メッセージ送信: $_selectedMessage');
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('閉じる'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  // メッセージ送信処理を更新
  void _sendMessage(String message) {
    setState(() {
      _sentMessage = message;
    });

    // 既存のタイマーをキャンセル
    _messageTimer?.cancel();

    // 新しいタイマーを設定（5秒後にメッセージを消去）
    _messageTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _sentMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel(); // タイマーをクリーンアップ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('バイクSNS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialPosition,
          initialZoom: 11.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          if (_currentPosition != null) ...[
            // 現在地が取得できている場合のみ表示
            MarkerLayer(
              markers: _otherUsersData.map((userData) {
                return Marker(
                  width: 80.0,
                  height: 80.0,
                  point: userData['position'],
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40.0,
                  ),
                );
              }).toList(),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 200.0,
                  height: 150.0,
                  point: _currentPosition!,
                  child: Column(
                    children: [
                      if (_sentMessage != null)
                        CustomPaint(
                          painter: BubblePainter(),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            constraints: const BoxConstraints(
                              maxWidth: 160.0,
                              maxHeight: 60.0,
                            ),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _sentMessage!,
                              style: const TextStyle(fontSize: 14.0),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height - 10),
        const Radius.circular(12),
      ))
      ..moveTo(size.width / 2 - 10, size.height - 10)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 10, size.height - 10)
      ..close();

    canvas.drawShadow(path, Colors.black, 2.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
