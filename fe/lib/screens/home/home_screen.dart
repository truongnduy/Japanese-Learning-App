import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/lesson_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/lesson_service.dart';
import '../../widgets/add_word_bottom_sheet.dart';
import '../lesson/flashcard_study_screen.dart';
import '../quiz/quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final LessonService _lessonService = LessonService();
  String _selectedLevel = 'N5';
  late Future<List<LessonModel>> _lessonsFuture;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 0; // 0: Bài học, 1: Ôn tập SRS, 2: Kiểm tra, 3: Cá nhân
  bool _dailyReminder = true;

  final List<Map<String, dynamic>> _levels = [
    {'label': 'N5', 'desc': 'Sơ cấp 1', 'color': AppColors.primary},
    {'label': 'N4', 'desc': 'Sơ cấp 2', 'color': const Color(0xFF2563EB)},
    {'label': 'N3', 'desc': 'Trung cấp', 'color': const Color(0xFFD97706)},
    {'label': 'N2', 'desc': 'Cao cấp', 'color': const Color(0xFF7C3AED)},
    {'label': 'N1', 'desc': 'Thành thạo', 'color': const Color(0xFF059669)},
  ];

  List<LessonModel> _currentLessons = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _fetchLessons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _fetchLessons() {
    setState(() {
      _lessonsFuture = _lessonService.getLessons(
        level: _selectedLevel,
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
    });
  }

  void _openAddWordModal({String? lessonId}) async {
    final result = await AddWordBottomSheet.show(
      context,
      initialLevel: _selectedLevel,
      lessons: _currentLessons,
      preselectedLessonId: lessonId,
      onWordAdded: () {
        _fetchLessons();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Đã lưu từ vựng / Flashcard thành công!'),
              ],
            ),
            backgroundColor: AppColors.accentMatcha,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
    if (result != null) {
      _fetchLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(user, authProvider),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildLessonsTab(user),
          _buildSRSTab(),
          _buildQuizTab(),
          _buildProfileTab(user, authProvider),
        ],
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              label: const Text(
                'Thêm Từ / Flashcard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _openAddWordModal(),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── APPBAR ĐỔI THEO TAB ──────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(UserModel? user, AuthProvider authProvider) {
    if (_currentNavIndex == 0) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Center(
                child: Text('⛩️', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Kotoba ',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'ことば',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Khám Phá / Bài Học',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE4E6)),
            ),
            child: const Row(
              children: [
                Text('🔥', style: TextStyle(fontSize: 13)),
                SizedBox(width: 4),
                Text(
                  '12',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 3),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(
                  (user?.name != null && user!.name.isNotEmpty) ? user.name[0].toUpperCase() : 'A',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      );
    } else {
      String title = 'Kotoba';
      if (_currentNavIndex == 1) title = 'Ôn Tập Trí Nhớ SRS';
      if (_currentNavIndex == 2) title = 'Kiểm Tra & Luyện Đề';
      if (_currentNavIndex == 3) title = 'Hồ Sơ Cá Nhân';

      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          if (_currentNavIndex != 3)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE4E6)),
              ),
              child: const Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 4),
                  Text('12', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
        ],
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 0: BÀI HỌC (DASHBOARD CHUẨN STITCH IMAGE 1)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLessonsTab(UserModel? user) {
    return FadeTransition(
      opacity: _fadeIn,
      child: RefreshIndicator(
        onRefresh: () async => _fetchLessons(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. HERO BANNER CHÀO MỪNG ──
              _buildHeroBanner(user?.name ?? 'Bạn'),

              // ── 2. CARD TRÍ NHỚ DÀI HẠN (SRS) ──
              _buildSRSCard(),

              // ── 3. SEARCH BAR TÌM KIẾM ──
              _buildSearchBar(),

              // ── 4. LỘ TRÌNH KIẾN THỨC (JLPT LEVEL TABS) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.map_outlined, size: 18, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Lộ trình kiến thức',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '5 cấp độ',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildLevelSelector(),
              const SizedBox(height: 24),

              // ── 5. HEADER DANH SÁCH BÀI HỌC ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DANH SÁCH BÀI HỌC $_selectedLevel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentLessons.length} Bài học',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 6. DANH SÁCH BÀI HỌC VỚI 4 TRẠNG THÁI STITCH ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FutureBuilder<List<LessonModel>>(
                  future: _lessonsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading();
                    }
                    if (snapshot.hasError) {
                      return _buildError(snapshot.error.toString());
                    }
                    final lessons = snapshot.data ?? [];
                    _currentLessons = lessons;
                    if (lessons.isEmpty) return _buildEmpty();
                    return _buildLessonList(lessons);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── 7. WIDGET KANJI MỖI NGÀY ──
              _buildDailyKanjiWidget(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: ÔN TẬP SRS (SPACED REPETITION HUB)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSRSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ tổng quan SRS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1818), Color(0xFF5C0D0D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF8B1818).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: const Text('THUẬT TOÁN SRS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18),
                        SizedBox(width: 4),
                        Text('Chuỗi 14 ngày', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '18 từ vựng đến hạn hôm nay',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hệ thống Spaced Repetition tính toán chính xác thời điểm vàng não bộ chuẩn bị quên để nhắc bạn ôn tập.',
                  style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_currentLessons.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlashcardStudyScreen(lesson: _currentLessons.first),
                          ),
                        ).then((_) => _fetchLessons());
                      } else {
                        _openAddWordModal();
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Bắt đầu ôn tập 18 từ ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4 Cấp độ SRS giải thích
          const Text('Các giai đoạn ghi nhớ não bộ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          _buildSRSRankItem('Giai đoạn 1: Chưa thuộc', '< 10 phút', 'Reset về đầu chu kỳ khi quên', const Color(0xFFDC2626)),
          const SizedBox(height: 8),
          _buildSRSRankItem('Giai đoạn 2: Đang nhớ', '1 ngày', 'Nhận biết được từ nhưng còn hơi vấp', const Color(0xFFEA580C)),
          const SizedBox(height: 8),
          _buildSRSRankItem('Giai đoạn 3: Nhớ tốt', '3 ngày', 'Phản xạ đọc và hiểu nghĩa nhanh chóng', const Color(0xFF2563EB)),
          const SizedBox(height: 8),
          _buildSRSRankItem('Giai đoạn 4-5: Đã thuộc lòng', '7 ngày - 1 tháng ✨', 'Khắc sâu vào trí nhớ dài hạn (Mastered)', const Color(0xFF15803D)),
          const SizedBox(height: 24),

          // Nút thêm từ vào SRS
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _openAddWordModal(),
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: const Text('Thêm từ vựng mới vào kho SRS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSRSRankItem(String title, String time, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: KIỂM TRA (QUIZ & TEST HUB)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuizTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thống kê thành tích Quiz
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🎯', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tỷ lệ đỗ trung bình', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('88% (Xuất sắc)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      SizedBox(height: 2),
                      Text('Đã hoàn thành 12 bài kiểm tra', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Chọn bài học để làm bài kiểm tra:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          if (_currentLessons.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('Đang tải danh sách bài kiểm tra...', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentLessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = _currentLessons[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${lesson.order}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.quiz_outlined, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text('${lesson.totalQuestions} câu • 10 phút', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(lesson: lesson),
                            ),
                          );
                        },
                        child: const Text('Vào thi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3: CÁ NHÂN (USER PROFILE HUB)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfileTab(UserModel? user, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      child: Column(
        children: [
          // Thẻ thông tin cá nhân
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (user?.name != null && user!.name.isNotEmpty) ? user.name[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Nguyễn Văn A',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'student@kotoba.edu.vn',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Học viên Kotoba • VIP Member',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Thẻ mục tiêu JLPT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF1EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF8E3DD)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.flag_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mục tiêu hiện tại: JLPT N5 → N4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text('Đã đạt 68% lộ trình học sơ cấp', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Thống kê cá nhân
          Row(
            children: [
              _buildProfileStatItem('14 Ngày', 'Chuỗi liên tiếp', '🔥', const Color(0xFFEA580C)),
              const SizedBox(width: 10),
              _buildProfileStatItem('86 Từ', 'Đã thuộc lòng', '🛡️', const Color(0xFF16A34A)),
              const SizedBox(width: 10),
              _buildProfileStatItem('88%', 'Tỉ lệ chính xác', '🎯', const Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 20),

          // Menu Cài đặt & Tiện ích
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Nhắc nhở học tập hàng ngày', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Thông báo lúc 20:00 mỗi tối', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  value: _dailyReminder,
                  onChanged: (val) => setState(() => _dailyReminder = val),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFF2563EB), size: 22),
                  title: const Text('Ngôn ngữ giao diện', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: const Text('Tiếng Việt (VI) ›', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.star_border_rounded, color: Colors.amber, size: 22),
                  title: const Text('Sổ tay từ vựng & Câu hỏi cần ôn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng Sổ tay ôn tập riêng đang mở'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 22),
                  title: const Text('Điều khoản dịch vụ & Chính sách', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nút Đăng xuất
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                backgroundColor: const Color(0xFFFFF1F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Đăng xuất tài khoản?'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi Kotoba không?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  authProvider.logout();
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: const Text('Đăng xuất tài khoản', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatItem(String value, String label, String icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CÁC WIDGET CON DÙNG TRONG DASHBOARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeroBanner(String name) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF8E3DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      '14 Ngày liên tiếp',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 13, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text(
                      'Mục tiêu: N5 → N4',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Konnichiwa, $name! 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hôm nay tâm trí sáng rõ, hãy cùng tích luỹ thêm tri thức mới nhé.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.track_changes_rounded, color: Color(0xFF16A34A), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mục tiêu ngày: 7/10 từ mới',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Còn 3 từ để duy trì chuỗi huy hiệu...',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.7,
                      minHeight: 6,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSRSCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Trí nhớ dài hạn (SRS)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _currentNavIndex = 1),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE5E5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cần ôn hôm nay', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '18',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          SizedBox(width: 4),
                          Text('từ vựng', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('SRS đợt sáng', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đã thuộc lòng', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Icon(Icons.shield_outlined, size: 14, color: Color(0xFF16A34A)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '86',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                          SizedBox(width: 4),
                          Text('từ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text('SRS Level ≥ 4', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2563EB), width: 3),
                  ),
                  child: const Center(
                    child: Text('88%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Độ chính xác Quiz', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('Tỉ lệ xuất sắc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tổng tích lũy', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text('142 từ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (_currentLessons.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashcardStudyScreen(lesson: _currentLessons.first),
                    ),
                  ).then((_) => _fetchLessons());
                } else {
                  _openAddWordModal();
                }
              },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text(
                'Ôn tập ngay 18 từ đến hạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _fetchLessons(),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài học, chủ đề từ vựng...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
            onPressed: () => _fetchLessons(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = _selectedLevel == level['label'];

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() => _selectedLevel = level['label'] as String);
                _fetchLessons();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${level['label']} (${level['desc']})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonList(List<LessonModel> lessons) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildStitchLessonCard(lessons[index], index),
    );
  }

  Widget _buildStitchLessonCard(LessonModel lesson, int index) {
    final bool isCompleted = index == 0;
    final bool isInProgress = index == 1;
    final bool isLocked = index >= 3;

    Color badgeColor = const Color(0xFF64748B);
    Color badgeBg = const Color(0xFFF1F5F9);
    String badgeText = 'Chưa bắt đầu';
    IconData badgeIcon = Icons.hourglass_empty_rounded;

    if (isCompleted) {
      badgeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = 'Đã làm chủ';
      badgeIcon = Icons.check_circle_outline_rounded;
    } else if (isInProgress) {
      badgeColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFDBEAFE);
      badgeText = 'Đang học dở';
      badgeIcon = Icons.trending_up_rounded;
    } else if (isLocked) {
      badgeColor = const Color(0xFF94A3B8);
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = 'Mở khóa sau Bài ${lesson.order - 1}';
      badgeIcon = Icons.lock_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: isLocked
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLocked
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashcardStudyScreen(lesson: lesson),
                    ),
                  ).then((_) => _fetchLessons());
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(badgeIcon, size: 12, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(
                                badgeText,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bài ${lesson.order < 10 ? "0${lesson.order}" : "${lesson.order}"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey.shade100 : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : (isInProgress
                                ? Icons.menu_book_rounded
                                : (isLocked ? Icons.lock_clock_rounded : Icons.explore_outlined)),
                        size: 16,
                        color: isCompleted
                            ? const Color(0xFF16A34A)
                            : (isInProgress ? const Color(0xFF2563EB) : (isLocked ? Colors.grey : const Color(0xFF2563EB))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey.shade500 : AppColors.textPrimary,
                  ),
                ),
                if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lesson.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${lesson.totalWords} từ vựng', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(Icons.quiz_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${lesson.totalQuestions} câu trắc nghiệm', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isCompleted)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 4,
                      backgroundColor: Color(0xFFDCFCE7),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    ),
                  )
                else if (isInProgress)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 4,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F52BA)),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCompleted
                          ? '100% Hoàn tất • ${lesson.totalWords}/${lesson.totalWords} đã nhớ'
                          : (isInProgress
                              ? '65% Hoàn thành'
                              : (isLocked ? 'Cần hoàn thành Bài ${lesson.order - 1}' : '0% • Sẵn sàng học')),
                      style: TextStyle(
                        fontSize: 11,
                        color: isCompleted ? const Color(0xFF15803D) : AppColors.textSecondary,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        if (!isLocked) ...[
                          IconButton(
                            tooltip: 'Làm bài trắc nghiệm Quiz',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.quiz_outlined, color: AppColors.primary, size: 18),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(lesson: lesson),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted
                                ? const Color(0xFFF1F5F9)
                                : (isInProgress ? AppColors.primary : (isLocked ? const Color(0xFFE2E8F0) : Colors.white)),
                            foregroundColor: isCompleted
                                ? AppColors.textPrimary
                                : (isInProgress ? Colors.white : (isLocked ? Colors.grey.shade400 : AppColors.primary)),
                            elevation: isInProgress ? 2 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            side: (!isCompleted && !isInProgress && !isLocked)
                                ? const BorderSide(color: AppColors.primary)
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isLocked
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FlashcardStudyScreen(lesson: lesson),
                                    ),
                                  ).then((_) => _fetchLessons());
                                },
                          child: Text(
                            isCompleted ? 'Ôn tập' : (isInProgress ? 'Tiếp tục học' : (isLocked ? 'Chưa mở' : 'Bắt đầu')),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyKanjiWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE5E5)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD4D4)),
            ),
            child: const Center(
              child: Text(
                '桜',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'KANJI MỖI NGÀY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'さくら • Sakura',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Hoa anh đào (Anh)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Biểu tượng của sự tươi mới, thanh khiết và tinh thần samurai kiên cường.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAVIGATION BAR (4 TABS CHUYỂN MÀN CHÍNH XÁC) ─────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Bài học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            label: 'Ôn tập SRS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Kiểm tra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không thể kết nối',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Hãy đảm bảo Rails server đang chạy.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _fetchLessons,
                  child: const Text(
                    'Thử lại →',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '📭',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài học $_selectedLevel',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy thử cấp độ N5 hoặc N4 để bắt đầu!',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _openAddWordModal(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Thêm từ vựng cho $_selectedLevel',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
