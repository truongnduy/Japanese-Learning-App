import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/lesson_model.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';

class AddWordBottomSheet extends StatefulWidget {
  final String? initialLevel;
  final List<LessonModel> lessons;
  final String? preselectedLessonId;
  final VoidCallback? onWordAdded;

  const AddWordBottomSheet({
    super.key,
    this.initialLevel,
    this.lessons = const [],
    this.preselectedLessonId,
    this.onWordAdded,
  });

  static Future<WordModel?> show(
    BuildContext context, {
    String? initialLevel,
    List<LessonModel> lessons = const [],
    String? preselectedLessonId,
    VoidCallback? onWordAdded,
  }) {
    return showModalBottomSheet<WordModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWordBottomSheet(
        initialLevel: initialLevel,
        lessons: lessons,
        preselectedLessonId: preselectedLessonId,
        onWordAdded: onWordAdded,
      ),
    );
  }

  @override
  State<AddWordBottomSheet> createState() => _AddWordBottomSheetState();
}

class _AddWordBottomSheetState extends State<AddWordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kanjiController = TextEditingController();
  final _hiraganaController = TextEditingController();
  final _romajiController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _exampleMeaningController = TextEditingController();

  final WordService _wordService = WordService();
  bool _isLoading = false;
  bool _isCardFlipped = false;

  late int _selectedLevel;
  String? _selectedLessonId;

  final Map<int, Map<String, dynamic>> _levelMap = {
    1: {'label': 'N5', 'color': const Color(0xFF4CAF50)},
    2: {'label': 'N4', 'color': const Color(0xFF2196F3)},
    3: {'label': 'N3', 'color': const Color(0xFFFF9800)},
    4: {'label': 'N2', 'color': const Color(0xFFE84A5F)},
    5: {'label': 'N1', 'color': const Color(0xFF9C27B0)},
  };

  @override
  void initState() {
    super.initState();
    _selectedLevel = _parseLevel(widget.initialLevel ?? 'N5');
    _selectedLessonId = widget.preselectedLessonId;
  }

  int _parseLevel(String level) {
    switch (level) {
      case 'N1':
        return 5;
      case 'N2':
        return 4;
      case 'N3':
        return 3;
      case 'N4':
        return 2;
      case 'N5':
      default:
        return 1;
    }
  }

  @override
  void dispose() {
    _kanjiController.dispose();
    _hiraganaController.dispose();
    _romajiController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _exampleMeaningController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newWord = await _wordService.createWord(
        kanji: _kanjiController.text.trim(),
        hiragana: _hiraganaController.text.trim(),
        romaji: _romajiController.text.trim(),
        vietnameseMeaning: _meaningController.text.trim(),
        difficultyLevel: _selectedLevel,
        exampleSentence: _exampleController.text.trim(),
        exampleMeaning: _exampleMeaningController.text.trim(),
        lessonId: _selectedLessonId,
      );

      if (mounted) {
        widget.onWordAdded?.call();
        Navigator.pop(context, newWord);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeColor = _levelMap[_selectedLevel]!['color'] as Color;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header kéo xuống
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề & đóng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.note_add_rounded, color: activeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thêm Từ Vựng / Flashcard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tạo thẻ ghi nhớ từ mới • 新しい単語',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          ),
          const Divider(height: 24, thickness: 1),

          // Nội dung cuộn
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── PREVIEW FLASHCARD THẺ SỐNG ──
                    _buildFlashcardPreview(activeColor),
                    const SizedBox(height: 20),

                    // ── CHỌN CẤP ĐỘ JLPT ──
                    const Text(
                      'Cấp độ JLPT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildLevelChips(),
                    const SizedBox(height: 16),

                    // ── GẮN VÀO BÀI HỌC (TÙY CHỌN) ──
                    if (widget.lessons.isNotEmpty) ...[
                      const Text(
                        'Bài học áp dụng (Tùy chọn)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      _buildLessonDropdown(),
                      const SizedBox(height: 16),
                    ],

                    // ── KANJI (Từ chính) ──
                    _buildTextField(
                      controller: _kanjiController,
                      label: 'Từ vựng / Kanji (Hán tự)',
                      hint: 'Ví dụ: 食べる, 日本, 桜, 勉強...',
                      prefixIcon: Icons.menu_book_rounded,
                      required: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // ── HIRAGANA & ROMAJI ──
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _hiraganaController,
                            label: 'Cách đọc (Hiragana)',
                            hint: 'Ví dụ: たべる',
                            prefixIcon: Icons.record_voice_over_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _romajiController,
                            label: 'Romaji (Phiên âm)',
                            hint: 'Ví dụ: taberu',
                            prefixIcon: Icons.spellcheck_rounded,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── NGHĨA TIẾNG VIỆT (BẮT BUỘC) ──
                    _buildTextField(
                      controller: _meaningController,
                      label: 'Ý nghĩa tiếng Việt',
                      hint: 'Ví dụ: Ăn, dùng bữa',
                      prefixIcon: Icons.translate_rounded,
                      required: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // ── CÂU VÍ DỤ ──
                    _buildTextField(
                      controller: _exampleController,
                      label: 'Câu ví dụ (Tùy chọn)',
                      hint: 'Ví dụ: ご飯を食べます。',
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // ── Ý NGHĨA CÂU VÍ DỤ ──
                    _buildTextField(
                      controller: _exampleMeaningController,
                      label: 'Dịch nghĩa ví dụ (Tùy chọn)',
                      hint: 'Ví dụ: Tôi ăn cơm.',
                      prefixIcon: Icons.subtitles_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // ── NÚT LƯU TỪ VỰNG ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_task_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lưu Flashcard (${_levelMap[_selectedLevel]!['label']})',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Preview thẻ flashcard trực quan
  Widget _buildFlashcardPreview(Color color) {
    final kanji = _kanjiController.text.trim().isEmpty ? '漢字' : _kanjiController.text.trim();
    final hiragana = _hiraganaController.text.trim().isEmpty ? 'ひらがな' : _hiraganaController.text.trim();
    final romaji = _romajiController.text.trim().isEmpty ? 'romaji' : _romajiController.text.trim();
    final meaning = _meaningController.text.trim().isEmpty ? 'Ý nghĩa tiếng Việt' : _meaningController.text.trim();
    final levelName = _levelMap[_selectedLevel]!['label'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Xem trước Thẻ Flashcard',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: () => setState(() => _isCardFlipped = !_isCardFlipped),
              child: Row(
                children: [
                  Icon(Icons.flip_camera_android_rounded, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    _isCardFlipped ? 'Xem mặt trước' : 'Xem mặt sau',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _isCardFlipped = !_isCardFlipped),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isCardFlipped
                    ? [const Color(0xFF2B3A67), const Color(0xFF1E284A)]
                    : [color.withValues(alpha: 0.1), color.withValues(alpha: 0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isCardFlipped ? Colors.transparent : color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isCardFlipped ? Colors.white24 : color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        levelName,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      _isCardFlipped ? 'MẶT SAU (NGHĨA)' : 'MẶT TRƯỚC (TỪ)',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: _isCardFlipped ? Colors.white60 : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isCardFlipped) ...[
                  Text(
                    hiragana,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kanji,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    romaji,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_exampleController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _exampleController.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    if (_exampleMeaningController.text.isNotEmpty)
                      Text(
                        _exampleMeaningController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.white54, fontStyle: FontStyle.italic),
                      ),
                  ],
                ],
                const SizedBox(height: 6),
                Text(
                  '💡 Nhấn để lật thẻ',
                  style: TextStyle(fontSize: 10, color: _isCardFlipped ? Colors.white38 : Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _levelMap.entries.map((entry) {
        final levelNum = entry.key;
        final label = entry.value['label'] as String;
        final color = entry.value['color'] as Color;
        final isSelected = _selectedLevel == levelNum;

        return GestureDetector(
          onTap: () => setState(() => _selectedLevel = levelNum),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonDropdown() {
    return DropdownButtonFormField<String?>(
      initialValue: _selectedLessonId,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Không gắn bài học (Từ vựng tự do)'),
        ),
        ...widget.lessons.map(
          (lesson) => DropdownMenuItem<String?>(
            value: lesson.id,
            child: Text(
              'Bài ${lesson.order}: ${lesson.title}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _selectedLessonId = value),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool required = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng không để trống trường này';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }
}
