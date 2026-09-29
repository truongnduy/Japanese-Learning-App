import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/word_model.dart';

class HandwritingCanvasDialog extends StatefulWidget {
  final WordModel word;

  const HandwritingCanvasDialog({super.key, required this.word});

  static Future<void> show(BuildContext context, WordModel word) {
    return showDialog(
      context: context,
      builder: (context) => HandwritingCanvasDialog(word: word),
    );
  }

  @override
  State<HandwritingCanvasDialog> createState() => _HandwritingCanvasDialogState();
}

class _HandwritingCanvasDialogState extends State<HandwritingCanvasDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _showGuide = true;

  @override
  Widget build(BuildContext context) {
    final charToDraw = widget.word.kanji.isNotEmpty ? widget.word.kanji : widget.word.hiragana;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiêu đề & đóng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gesture_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Luyện Viết Tay Kanji',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Tô theo nét chữ hoặc tự viết',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ô Canvas tập viết chữ thập
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Đường kẻ chữ thập mờ
                    const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1),

                    // Chữ mờ làm mẫu (Guide watermark)
                    if (_showGuide)
                      Center(
                        child: Text(
                          charToDraw,
                          style: TextStyle(
                            fontSize: 160,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                      ),

                    // Vùng nhận nét vẽ của người dùng
                    GestureDetector(
                      onPanStart: (details) {
                        final localPos = details.localPosition;
                        setState(() {
                          _currentStroke = [localPos];
                          _strokes.add(_currentStroke);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStroke.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _currentStroke = [];
                        });
                      },
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: _KanjiDrawingPainter(strokes: _strokes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Toolbar điều khiển nét vẽ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle nét mẫu
                TextButton.icon(
                  onPressed: () => setState(() => _showGuide = !_showGuide),
                  icon: Icon(
                    _showGuide ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 16,
                    color: const Color(0xFF2563EB),
                  ),
                  label: Text(
                    _showGuide ? 'Ẩn nét mẫu' : 'Hiện nét mẫu',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),

                // Xóa viết lại
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _strokes.clear();
                      _currentStroke.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.error),
                  label: const Text('Xóa viết lại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nút hoàn thành
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentMatcha,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Đã ghi nhận luyện viết tay thành công! 🎉'),
                        ],
                      ),
                      backgroundColor: AppColors.accentMatcha,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Hoàn tất luyện viết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _KanjiDrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 10.0;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 5.0, paint);
      } else {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KanjiDrawingPainter oldDelegate) => true;
}
