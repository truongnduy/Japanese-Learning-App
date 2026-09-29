import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/lesson_model.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final LessonModel lesson;
  final Map<String, dynamic> resultData;
  final int timeSpentSeconds;

  const QuizResultScreen({
    super.key,
    required this.lesson,
    required this.resultData,
    this.timeSpentSeconds = 255,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  String _selectedFilter = 'all'; // 'all', 'wrong', 'correct'
  final Set<String> _bookmarkedQuestions = {};

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.resultData['score'] as num?)?.toDouble() ?? 0.0;
    final totalQuestions = widget.resultData['total_questions'] as int? ?? 10;
    final correctCount = widget.resultData['correct_count'] as int? ?? 0;
    final wrongCount = totalQuestions - correctCount;
    final passed = widget.resultData['passed'] as bool? ?? (score >= 60.0);
    final List feedbackList = widget.resultData['feedback'] ?? [];

    List filteredFeedback = feedbackList;
    if (_selectedFilter == 'wrong') {
      filteredFeedback = feedbackList.where((f) => f['is_correct'] != true).toList();
    } else if (_selectedFilter == 'correct') {
      filteredFeedback = feedbackList.where((f) => f['is_correct'] == true).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kết Quả Kiểm Tra',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          children: [
            // ── BADGE KẾT QUẢ ĐẠT CHUẨN ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (passed ? AppColors.accentMatcha : AppColors.error).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (passed ? AppColors.accentMatcha : AppColors.error).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    passed ? Icons.verified_rounded : Icons.info_outline_rounded,
                    color: passed ? AppColors.accentMatcha : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    passed ? 'XUẤT SẮC! ĐẠT CHUẨN (PASSED)' : 'CHƯA ĐẠT CHUẨN (CẦN ÔN LẠI)',
                    style: TextStyle(
                      color: passed ? AppColors.accentMatcha : AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── VÒNG TRÒN ĐIỂM SỐ ──
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        passed ? AppColors.accentMatcha : AppColors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toInt()}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${score.toInt()} / 100 điểm',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề bài học
            Text(
              'Bài ${widget.lesson.order}: ${widget.lesson.title}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              passed
                  ? 'Bạn đã hoàn thành xuất sắc bài kiểm tra với kết quả vượt chuẩn quy định (≥ 60%).'
                  : 'Hãy ôn lại các từ chưa thuộc và làm lại bài kiểm tra để nâng cao điểm số nhé!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // ── 3 STATS CARD ──
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF0284C7),
                  title: 'Thời gian',
                  value: _formatTime(widget.timeSpentSeconds),
                  subtitle: 'phút:giây',
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.accentMatcha,
                  title: 'Số câu đúng',
                  value: '$correctCount/$totalQuestions',
                  subtitle: 'Tỷ lệ ${(correctCount / (totalQuestions > 0 ? totalQuestions : 1) * 100).toInt()}%',
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFE65100),
                  title: 'SRS Bonus',
                  value: '+${correctCount * 10}',
                  subtitle: 'kinh nghiệm',
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── TIÊU ĐỀ CHI TIẾT & BỘ LỌC ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Xem lại chi tiết bài làm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalQuestions câu hỏi',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter pills
            Row(
              children: [
                _buildFilterChip('all', 'Tất cả ($totalQuestions)'),
                const SizedBox(width: 8),
                _buildFilterChip('wrong', 'Cần ôn lại ($wrongCount) 🔴', isWarning: wrongCount > 0),
                const SizedBox(width: 8),
                _buildFilterChip('correct', 'Đã nhớ ($correctCount)'),
              ],
            ),
            const SizedBox(height: 16),

            // ── DANH SÁCH CÂU HỎI REVIEW ──
            if (filteredFeedback.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _selectedFilter == 'wrong' ? '🎉 Tuyệt vời! Bạn không sai câu nào.' : 'Không có câu hỏi phù hợp.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFeedback.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = filteredFeedback[index];
                  return _buildQuestionReviewCard(item, index + 1);
                },
              ),
            const SizedBox(height: 24),

            // ── CARD SENSEI NHẬN XÉT ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD0DCFF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('👩‍🏫', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sensei Nhận Xét',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          passed
                              ? 'Tuyệt lắm! Bạn đã nắm rất vững kiến thức bài học này. Hãy tiếp tục duy trì phong độ nhé!'
                              : 'Đừng nản lòng! Hãy ôn lại các từ chưa thuộc trong thẻ Flashcard rồi thử sức lại lần nữa nhé.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── ACTION BUTTONS ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(lesson: widget.lesson),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Làm lại bài kiểm tra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.list_alt_rounded, size: 18, color: AppColors.textPrimary),
                    label: const Text('Danh sách bài', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isWarning = false}) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isWarning ? AppColors.error : AppColors.textPrimary)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isWarning ? AppColors.error : AppColors.textPrimary)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionReviewCard(dynamic item, int displayIndex) {
    final bool isCorrect = item['is_correct'] == true;
    final String qText = item['question_text'] ?? '';
    final String selectedAns = item['selected_answer'] ?? 'Chưa chọn';
    final String correctAns = item['correct_answer'] ?? '';
    final String? explanation = item['explanation'];
    final String qId = item['question_id']?.toString() ?? '$displayIndex';
    final bool isBookmarked = _bookmarkedQuestions.contains(qId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect ? AppColors.accentMatcha.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? AppColors.accentMatcha : AppColors.error).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCorrect ? AppColors.accentMatcha : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 14,
                      color: isCorrect ? AppColors.accentMatcha : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect ? 'Chính xác' : 'Cần chú ý',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? AppColors.accentMatcha : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Câu $displayIndex',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nội dung câu hỏi
          Text(
            qText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          // Lựa chọn của bạn
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.accentMatcha.withValues(alpha: 0.06) : AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  'Lựa chọn của bạn: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Expanded(
                  child: Text(
                    '$selectedAns ${isCorrect ? "✓" : "✗"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? AppColors.accentMatcha : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isCorrect && correctAns.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentMatcha.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'Đáp án chính xác: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Expanded(
                    child: Text(
                      '$correctAns ✓',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentMatcha,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Giải thích chi tiết
          if (explanation != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanation,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Nút thêm vào sổ tay ôn tập
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  if (isBookmarked) {
                    _bookmarkedQuestions.remove(qId);
                  } else {
                    _bookmarkedQuestions.add(qId);
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBookmarked ? 'Đã xóa khỏi sổ tay' : 'Đã thêm vào Sổ tay ôn tập riêng ⭐'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBookmarked ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: isBookmarked ? AppColors.primary : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBookmarked ? 'Đã lưu trong Sổ tay' : 'Thêm vào Sổ tay ôn tập riêng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBookmarked ? AppColors.primary : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
