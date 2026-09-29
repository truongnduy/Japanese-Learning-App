# frozen_string_literal: true

puts "== Cleaning existing MongoDB collections =="
[User, Lesson, Word, QuizQuestion, QuizAttempt, UserWordProgress].each do |model|
  model.delete_all
end

puts "== Creating Users =="
admin = User.create!(
  name: "Sensei Tanaka",
  email: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: "admin"
)

student = User.create!(
  name: "Nguyễn Văn A",
  email: "student@example.com",
  password: "password123",
  password_confirmation: "password123",
  role: "student"
)

puts "== Creating Lessons =="
lesson1 = Lesson.create!(
  title: "Bài 1: Giới thiệu bản thân & Chào hỏi",
  description: "Làm quen với các từ vựng chào hỏi, xưng hô và quốc gia cơ bản trong tiếng Nhật.",
  level: "N5",
  order: 1,
  user: admin
)

lesson2 = Lesson.create!(
  title: "Bài 2: Ăn uống & Sinh hoạt hàng ngày",
  description: "Các từ vựng về đồ ăn, thức uống, hành động ăn uống và mua sắm thực phẩm.",
  level: "N5",
  order: 2,
  user: admin
)

lesson3 = Lesson.create!(
  title: "Bài 3: Thời gian & Lịch trình",
  description: "Cách nói giờ giấc, ngày tháng, các hoạt động đi lại hàng ngày.",
  level: "N4",
  order: 3,
  user: admin
)

puts "== Creating Words for Lesson 1 =="
w1_1 = Word.create!(
  lesson: lesson1,
  kanji: "人",
  romaji: "hito / jin",
  hiragana: "ひと",
  vietnamese_meaning: "Người",
  difficulty_level: 1,
  example_sentence: "あの人は日本人です。",
  example_meaning: "Người kia là người Nhật.",
  kanji_strokes: [
    KanjiStroke.new(stroke_number: 1, stroke_order: 1, stroke_type: "slant_left", svg_path: "M 50,20 Q 30,60 15,90", direction: "top_to_bottom_left"),
    KanjiStroke.new(stroke_number: 2, stroke_order: 2, stroke_type: "slant_right", svg_path: "M 38,48 Q 60,70 85,90", direction: "top_to_bottom_right")
  ]
)

w1_2 = Word.create!(
  lesson: lesson1,
  kanji: "日",
  romaji: "hi / nichi",
  hiragana: "ひ",
  vietnamese_meaning: "Mặt trời, ngày",
  difficulty_level: 1,
  example_sentence: "今日はいい日ですね。",
  example_meaning: "Hôm nay là một ngày đẹp trời nhỉ.",
  kanji_strokes: [
    KanjiStroke.new(stroke_number: 1, stroke_order: 1, stroke_type: "vertical", svg_path: "M 30,20 L 30,80", direction: "top_to_bottom"),
    KanjiStroke.new(stroke_number: 2, stroke_order: 2, stroke_type: "horizontal_vertical", svg_path: "M 30,20 L 70,20 L 70,80", direction: "left_to_right_down"),
    KanjiStroke.new(stroke_number: 3, stroke_order: 3, stroke_type: "horizontal", svg_path: "M 30,50 L 70,50", direction: "left_to_right"),
    KanjiStroke.new(stroke_number: 4, stroke_order: 4, stroke_type: "horizontal", svg_path: "M 30,80 L 70,80", direction: "left_to_right")
  ]
)

w1_3 = Word.create!(
  lesson: lesson1,
  kanji: "本",
  romaji: "hon",
  hiragana: "ほん",
  vietnamese_meaning: "Sách, gốc rễ, nguồn cội",
  difficulty_level: 1,
  example_sentence: "日本語の本を読みます。",
  example_meaning: "Tôi đọc sách tiếng Nhật."
)

w1_4 = Word.create!(
  lesson: lesson1,
  kanji: "私",
  romaji: "watashi",
  hiragana: "わたし",
  vietnamese_meaning: "Tôi",
  difficulty_level: 1,
  example_sentence: "私はベトナム人です。",
  example_meaning: "Tôi là người Việt Nam."
)

puts "== Creating Words for Lesson 2 =="
w2_1 = Word.create!(
  lesson: lesson2,
  kanji: "食",
  romaji: "shoku / taberu",
  hiragana: "たべる",
  vietnamese_meaning: "Ăn, thực phẩm",
  difficulty_level: 1,
  example_sentence: "朝ご飯を食べます。",
  example_meaning: "Tôi ăn bữa sáng.",
  kanji_strokes: [
    KanjiStroke.new(stroke_number: 1, stroke_order: 1, stroke_type: "slant_left", svg_path: "M 50,10 Q 35,25 20,40", direction: "top_to_left"),
    KanjiStroke.new(stroke_number: 2, stroke_order: 2, stroke_type: "slant_right", svg_path: "M 48,22 Q 65,30 80,45", direction: "top_to_right"),
    KanjiStroke.new(stroke_number: 3, stroke_order: 3, stroke_type: "horizontal", svg_path: "M 35,40 L 65,40", direction: "left_to_right")
  ]
)

w2_2 = Word.create!(
  lesson: lesson2,
  kanji: "飲",
  romaji: "in / nomu",
  hiragana: "のむ",
  vietnamese_meaning: "Uống",
  difficulty_level: 1,
  example_sentence: "お茶を飲みます。",
  example_meaning: "Tôi uống trà."
)

w2_3 = Word.create!(
  lesson: lesson2,
  kanji: "水",
  romaji: "mizu / sui",
  hiragana: "みず",
  vietnamese_meaning: "Nước",
  difficulty_level: 1,
  example_sentence: "冷たい水をください。",
  example_meaning: "Xin vui lòng cho tôi nước lạnh."
)

puts "== Creating Quiz Questions for Lesson 1 =="
QuizQuestion.create!(
  lesson: lesson1,
  question_type: "multiple_choice",
  question_text: "Chữ Hán '人' có nghĩa là gì?",
  options: ["A. Sách", "B. Mặt trời", "C. Người", "D. Nước"],
  correct_answer: "C",
  explanation: "Chữ '人' (Hán Việt: Nhân) có nghĩa là 'Người'. Ví dụ: 日本人 (người Nhật).",
  points: 10
)

QuizQuestion.create!(
  lesson: lesson1,
  question_type: "multiple_choice",
  question_text: "Cách đọc Hiragana của chữ '日' trong '日曜日' là gì?",
  options: ["A. にち", "B. ほん", "C. ひと", "D. みず"],
  correct_answer: "A",
  explanation: "Trong '日曜日', chữ 日 đầu tiên đọc là 'にち' (nichi).",
  points: 10
)

QuizQuestion.create!(
  lesson: lesson1,
  question_type: "multiple_choice",
  question_text: "Điền từ thích hợp vào chỗ trống: 私___ベトナム人です。",
  options: ["A. を", "B. は", "C. に", "D. で"],
  correct_answer: "B",
  explanation: "Trợ từ 'は' (đọc là wa) biểu thị chủ ngữ trong câu khẳng định.",
  points: 10
)

puts "== Creating Quiz Questions for Lesson 2 =="
QuizQuestion.create!(
  lesson: lesson2,
  question_type: "multiple_choice",
  question_text: "Từ nào sau đây mang nghĩa là 'Ăn'?",
  options: ["A. 飲みます", "B. 行きます", "C. 食べます", "D. 見ます"],
  correct_answer: "C",
  explanation: "Chữ '食' ghép thành động từ '食べます' (tabemasu) nghĩa là ăn.",
  points: 10
)

QuizQuestion.create!(
  lesson: lesson2,
  question_type: "multiple_choice",
  question_text: "Chữ Hán '水' có âm Romaji là gì?",
  options: ["A. mizu", "B. ocha", "C. hon", "D. hito"],
  correct_answer: "A",
  explanation: "Chữ '水' (Thủy) đọc là 'mizu', có nghĩa là nước uống thông thường.",
  points: 10
)

puts "== Initializing sample study progress for student =="
UserWordProgress.create!(
  user: student,
  word: w1_1,
  studied_at: 1.day.ago,
  proficiency_level: 3,
  review_count: 3,
  memorized: false
)

UserWordProgress.create!(
  user: student,
  word: w1_2,
  studied_at: 2.hours.ago,
  proficiency_level: 4,
  review_count: 5,
  memorized: true
)

puts "== Seed complete! MongoDB database populated successfully =="
