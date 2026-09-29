import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/word_model.dart';

class StrokeSimulationDialog extends StatefulWidget {
  final WordModel word;

  const StrokeSimulationDialog({super.key, required this.word});

  static Future<void> show(BuildContext context, WordModel word) {
    return showDialog(
      context: context,
      builder: (context) => StrokeSimulationDialog(word: word),
    );
  }

  @override
  State<StrokeSimulationDialog> createState() => _StrokeSimulationDialogState();
}

class _StrokeSimulationDialogState extends State<StrokeSimulationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentStep = 1;
  final int _totalStrokes = 5; // Mặc định 5 nét hoặc theo word

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _animController.addListener(() {
      final step = ((_animController.value * _totalStrokes).floor() + 1).clamp(1, _totalStrokes);
      if (step != _currentStep) {
        setState(() => _currentStep = step);
      }
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _replay() {
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final charToShow = widget.word.kanji.isNotEmpty ? widget.word.kanji : widget.word.hiragana;

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
                      child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô Phỏng Thứ Tự Nét',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Quan sát thứ tự và chiều hướng viết nét',
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

            // Ô hiển thị mô phỏng nét viết
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1),

                  // Chữ Kanji động
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.2 + (_animController.value * 0.8),
                        child: Text(
                          charToShow,
                          style: TextStyle(
                            fontSize: 140,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.9),
                          ),
                        ),
                      );
                    },
                  ),

                  // Số nét đang vẽ
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nét $_currentStep / $_totalStrokes',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thanh tiến độ mô phỏng
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) => LinearProgressIndicator(
                  value: _animController.value,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Điều khiển chạy lại
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _replay,
                    icon: const Icon(Icons.replay_rounded, size: 18, color: Color(0xFF2563EB)),
                    label: const Text('Phát lại từ đầu', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
