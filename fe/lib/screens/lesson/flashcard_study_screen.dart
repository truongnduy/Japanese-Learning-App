import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/lesson_model.dart';
import '../../models/word_model.dart';
import '../../services/lesson_service.dart';
import '../../services/word_service.dart';
import '../../widgets/add_word_bottom_sheet.dart';
import '../../widgets/handwriting_canvas_dialog.dart';
import '../../widgets/stroke_simulation_dialog.dart';
import '../quiz/quiz_screen.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final LessonModel lesson;

  const FlashcardStudyScreen({super.key, required this.lesson});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  final LessonService _lessonService = LessonService();
  final WordService _wordService = WordService();

  late Future<List<WordModel>> _wordsFuture;
  List<WordModel> _words = [];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _showNotes = true;
  bool _isBookmarked = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadWords();
  }

  void _loadWords() {
    setState(() {
      _wordsFuture = _lessonService.getLessonWords(widget.lesson.id);
    });
  }

  void _playAudio(WordModel word) {
    final text = word.hiragana.isNotEmpty ? word.hiragana : word.romaji;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('🔊 Đang phát âm: $text (${word.romaji})'),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleFlip() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _submitSRS(int srsLevel) async {
    if (_words.isEmpty) return;

    final currentWord = _words[_currentIndex];
    try {
      await _wordService.markWordStudied(currentWord.id);
    } catch (_) {}

    if (_currentIndex < _words.length - 1) {
      if (_showBack) {
        _flipController.reverse();
        _showBack = false;
      }
      setState(() => _currentIndex++);
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('🎉 Hoàn thành xuất sắc!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Bạn đã ôn tập xong ${_words.length} thẻ từ vựng của bài "${widget.lesson.title}"!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn đã sẵn sàng thử sức với bài kiểm tra trắc nghiệm chưa?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _showBack = false;
                _flipController.reset();
              });
            },
            child: const Text('Học lại từ đầu'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(lesson: widget.lesson),
                ),
              );
            },
            icon: const Icon(Icons.quiz_outlined, size: 18),
            label: const Text('Làm bài Quiz ngay'),
          ),
        ],
      ),
    );
  }

  void _openAddWord() {
    AddWordBottomSheet.show(
      context,
      initialLevel: widget.lesson.level,
      lessons: [widget.lesson],
      preselectedLessonId: widget.lesson.id,
      onWordAdded: () => _loadWords(),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Phiên Học SRS Tập Trung',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppColors.primary : AppColors.textPrimary,
            ),
            onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<WordModel>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadWords,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          _words = snapshot.data ?? [];

          if (_words.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có từ vựng nào trong bài này!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hãy là người đầu tiên thêm từ mới hoặc flashcard vào bài học.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _openAddWord,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm thẻ từ vựng đầu tiên', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentWord = _words[_currentIndex];
          final progressPercent = (_currentIndex + 1) / _words.length;

          return Column(
            children: [
              // ── SUBHEADER (Khớp chuẩn Stitch Image 3) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.lesson.level,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3730A3)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bài ${widget.lesson.order}: ${widget.lesson.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Thẻ ${_currentIndex + 1} / ${_words.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _openAddWord,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chu kỳ SRS vạch 5 nấc
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text(
                              'Chu kỳ SRS: Giai đoạn 2 (Đang nhớ)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(5, (idx) {
                            final isActive = idx < 2;
                            return Container(
                              width: 14,
                              height: 4,
                              margin: const EdgeInsets.only(left: 3),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── NỘI DUNG CUỘN THẺ FLASHCARD ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // Thẻ Flashcard chính có xoay lật 3D
                      GestureDetector(
                        onTap: _toggleFlip,
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value * pi;
                            final isUnder = angle > (pi / 2);

                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              alignment: Alignment.center,
                              child: isUnder
                                  ? Transform(
                                      transform: Matrix4.identity()..rotateY(pi),
                                      alignment: Alignment.center,
                                      child: _buildCardBack(currentWord),
                                    )
                                  : _buildCardFront(currentWord),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Gợi ý lật thẻ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flip_camera_android_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            _showBack ? 'Chạm để xem lại mặt trước (Từ & Hán tự)' : 'Chạm thẻ để lật xem nghĩa & ví dụ câu',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── GHI CHÚ DỊCH NGHĨA & MẸO GHI NHỚ (Stitch Accordion) ──
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() => _showNotes = !_showNotes),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_stories_outlined, size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text(
                                          'Ghi chú dịch nghĩa & Mẹo ghi nhớ',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      _showNotes ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showNotes)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: Text(
                                  currentWord.exampleSentence != null && currentWord.exampleSentence!.isNotEmpty
                                      ? 'Ví dụ: ${currentWord.exampleSentence!}\n${currentWord.exampleMeaning ?? ""}'
                                      : 'Chữ ${currentWord.kanji.isNotEmpty ? currentWord.kanji : currentWord.hiragana} tượng hình chuẩn nét Nhật. Luyện tập đều đặn với thẻ SRS để ghi nhớ lâu vào vỏ não.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── HÀNG NÚT ĐÁNH GIÁ ĐỘ NHỚ (4 MỨC ĐỘ SRS CHUẨN STITCH IMAGE 3) ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ĐÁNH GIÁ ĐỘ NHỚ (SRS FEEDBACK)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textSecondary),
                        ),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text('Chuỗi 4 ngày', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 2x2 Grid Buttons
                    Row(
                      children: [
                        // Mức 1: Chưa thuộc (<10 phút)
                        _buildSRSButton(
                          color: const Color(0xFFDC2626),
                          intervalText: '< 10 phút',
                          title: 'Chưa thuộc',
                          subtitle: 'Level 1 (Reset)',
                          onTap: () => _submitSRS(1),
                        ),
                        const SizedBox(width: 8),
                        // Mức 2: Khó nhớ (1 ngày)
                        _buildSRSButton(
                          color: const Color(0xFFEA580C),
                          intervalText: '1 ngày',
                          title: 'Khó nhớ',
                          subtitle: 'Level 2 (Hơi vấp)',
                          onTap: () => _submitSRS(2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Mức 3: Nhớ tốt (3 ngày)
                        _buildSRSButton(
                          color: const Color(0xFF2563EB),
                          intervalText: '3 ngày',
                          title: 'Nhớ tốt',
                          subtitle: 'Level 3 (Thành thạo)',
                          onTap: () => _submitSRS(3),
                        ),
                        const SizedBox(width: 8),
                        // Mức 4: Đã thuộc lòng (7 ngày)
                        _buildSRSButton(
                          color: const Color(0xFF15803D),
                          intervalText: '7 ngày ✨',
                          title: 'Đã thuộc lòng',
                          subtitle: 'Level 4-5 (Mastered)',
                          isSolid: true,
                          onTap: () => _submitSRS(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Mặt trước thẻ (Kanji + Ô nét viết + Nút mô phỏng)
  Widget _buildCardFront(WordModel word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Danh từ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('5 nét', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _playAudio(word),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text('Nghe chuẩn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Furigana
          Text(
            word.hiragana,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 2),

          // Kanji to
          Text(
            word.kanji.isNotEmpty ? word.kanji : word.hiragana,
            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),

          // Romaji & Nghĩa tóm tắt
          Text(
            'Romaji: ${word.romaji.isNotEmpty ? word.romaji : "..."} • ${word.vietnameseMeaning}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // ── THỨ TỰ NÉT VIẾT (STROKE ORDER BOX) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.draw_outlined, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Thứ tự nét viết (Stroke Order)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    Text('5 nét chuẩn', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),

                // Ô lưới chữ thập thư pháp Nhật
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Đường kẻ chữ thập mờ
                      const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                      const VerticalDivider(color: Color(0xFFF1F5F9), thickness: 1),
                      // Chữ Kanji với các điểm số nét
                      Center(
                        child: Text(
                          word.kanji.isNotEmpty ? word.kanji : word.hiragana,
                          style: TextStyle(
                            fontSize: 76,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      // Điểm đánh số nét mô phỏng
                      Positioned(
                        top: 24,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2 nút mô phỏng & viết tay
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => StrokeSimulationDialog.show(context, word),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text('Mô phỏng nét', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => HandwritingCanvasDialog.show(context, word),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gesture_rounded, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text('Luyện viết tay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mặt sau thẻ (Nghĩa tiếng Việt + Ví dụ)
  Widget _buildCardBack(WordModel word) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1818), Color(0xFF5C0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1818).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: const Text('MẶT SAU: Ý NGHĨA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 18),
          Text(
            word.vietnameseMeaning,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
          ),
          if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Text(
                    word.exampleSentence!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  if (word.exampleMeaning != null && word.exampleMeaning!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      word.exampleMeaning!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSRSButton({
    required Color color,
    required String intervalText,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSolid = false,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSolid ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            boxShadow: isSolid
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSolid ? Colors.white : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    intervalText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSolid ? Colors.white70 : color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSolid ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSolid ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
