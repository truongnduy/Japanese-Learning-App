# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

puts "== Running API Integration Verification =="

# 1. Test Models and MongoDB direct queries
puts "\n[1] Verifying MongoDB collections..."
user_count = User.count
lesson_count = Lesson.count
word_count = Word.count
question_count = QuizQuestion.count
progress_count = UserWordProgress.count

puts "   Users in DB: #{user_count}"
puts "   Lessons in DB: #{lesson_count}"
puts "   Words in DB: #{word_count}"
puts "   QuizQuestions in DB: #{question_count}"
puts "   UserWordProgresses in DB: #{progress_count}"

raise "Data mismatch!" unless user_count >= 2 && lesson_count >= 3 && word_count >= 7

# 2. Test JWT Token Generation and Decoding
puts "\n[2] Testing JWT Generation & Verification..."
user = User.find_by(email: "student@example.com")
token = JsonWebToken.encode(user_id: user.id.to_s)
decoded = JsonWebToken.decode(token)
puts "   Token generated: #{token[0..25]}..."
puts "   Decoded user_id: #{decoded[:user_id]}"
raise "JWT decode failure!" unless decoded[:user_id] == user.id.to_s

# 3. Test Lesson and Word queries
puts "\n[3] Testing Lesson & Word logic..."
lesson1 = Lesson.where(order: 1).first
puts "   Lesson 1: #{lesson1.title} (#{lesson1.level})"
puts "   Total words in Lesson 1: #{lesson1.total_words}"
puts "   Total questions in Lesson 1: #{lesson1.total_questions}"
raise "Lesson words mismatch!" unless lesson1.total_words >= 4

# Test Word serialization
word1 = lesson1.words.first
puts "   Word: #{word1.kanji} (#{word1.romaji}) - #{word1.vietnamese_meaning}"
puts "   Kanji Strokes count: #{word1.kanji_strokes.count}"

# 4. Test Quiz submission logic directly
puts "\n[4] Testing Quiz Evaluation logic..."
questions = lesson1.quiz_questions.to_a
q1 = questions[0]
puts "   Question 1: #{q1.question_text}"
puts "   Correct answer: #{q1.correct_answer}"
puts "   Checking answer 'C': #{q1.check_answer('C')}"
puts "   Checking answer 'B': #{q1.check_answer('B')}"
raise "Answer checking failed!" unless q1.check_answer("C") == true && q1.check_answer("B") == false

# 5. Test Study Progress creation
puts "\n[5] Testing Study Progress tracking..."
word_to_study = lesson1.words.last
existing_count = UserWordProgress.where(user_id: user.id, word_id: word_to_study.id).count
puts "   Pre-study record exists: #{existing_count > 0}"

progress = UserWordProgress.find_or_initialize_by(user_id: user.id, word_id: word_to_study.id)
progress.studied_at = Time.current
progress.proficiency_level = (progress.proficiency_level || 0) + 1
progress.review_count = (progress.review_count || 0) + 1
progress.save!
puts "   Study recorded: proficiency=#{progress.proficiency_level}, review_count=#{progress.review_count}"

# 6. Test QuizAttempt creation
puts "\n[6] Testing QuizAttempt creation..."
attempt = QuizAttempt.create!(
  user: user,
  lesson: lesson1,
  score: 100.0,
  earned_points: 30,
  total_points: 30,
  total_questions: 3,
  correct_count: 3,
  passed: true,
  answers: [
    { question_id: q1.id.to_s, selected_answer: "C", is_correct: true }
  ]
)
puts "   Attempt created: ID=#{attempt.id}, score=#{attempt.score}%, passed=#{attempt.passed}"
raise "Attempt creation failed!" unless attempt.persisted?

puts "\n== All core MongoDB business logic verified successfully! =="
