# frozen_string_literal: true

puts "\n== STARTING FULL HTTP CONTROLLER END-TO-END TESTS =="

app_session = ActionDispatch::Integration::Session.new(Rails.application)

# Helper for JSON request
def request_json(session, method, path, params = {}, headers = {})
  session.send(method, path, params: params, headers: headers)
  JSON.parse(session.response.body) rescue session.response.body
end

# 1. Test POST /api/v1/auth/login
puts "\n[1] Testing POST /api/v1/auth/login..."
res = request_json(app_session, :post, "/api/v1/auth/login", { email: "student@example.com", password: "password123" })
puts "   Status: #{app_session.response.status}"
puts "   Message: #{res['message']}"
puts "   Token: #{res['token'] ? res['token'][0..30] + '...' : 'NONE'}"
raise "Login failed!" unless app_session.response.status == 200 && res["token"].present?
token = res["token"]
auth_headers = { "Authorization" => "Bearer #{token}" }

# 2. Test GET /api/v1/auth/me
puts "\n[2] Testing GET /api/v1/auth/me (authenticated)..."
res = request_json(app_session, :get, "/api/v1/auth/me", {}, auth_headers)
puts "   Status: #{app_session.response.status}"
puts "   User: #{res.dig('user', 'name')} (#{res.dig('user', 'email')})"
puts "   Words studied: #{res.dig('statistics', 'words_studied_count')}"
raise "Get me failed!" unless app_session.response.status == 200

# 3. Test GET /api/v1/lessons
puts "\n[3] Testing GET /api/v1/lessons..."
res = request_json(app_session, :get, "/api/v1/lessons")
puts "   Status: #{app_session.response.status}"
puts "   Total lessons returned: #{res['data'].size}"
first_lesson = res['data'].first
puts "   Lesson 1: #{first_lesson['title']} - Total words: #{first_lesson['total_words']}"
raise "List lessons failed!" unless app_session.response.status == 200 && res['data'].size >= 3

# 4. Test GET /api/v1/lessons?level=N5
puts "\n[4] Testing GET /api/v1/lessons?level=N5..."
res = request_json(app_session, :get, "/api/v1/lessons?level=N5")
puts "   Status: #{app_session.response.status}"
puts "   N5 lessons: #{res['data'].map { |l| l['title'] }.join(', ')}"
raise "Filter lessons failed!" unless res['data'].all? { |l| l['level'] == "N5" }

lesson_id = first_lesson['id']

# 5. Test GET /api/v1/lessons/:lesson_id/words
puts "\n[5] Testing GET /api/v1/lessons/#{lesson_id}/words..."
res = request_json(app_session, :get, "/api/v1/lessons/#{lesson_id}/words", {}, auth_headers)
puts "   Status: #{app_session.response.status}"
puts "   Words count: #{res['data'].size}"
sample_word = res['data'].first
puts "   Sample word: #{sample_word['kanji']} - #{sample_word['romaji']} - #{sample_word['meaning']} (Studied: #{sample_word['is_studied']})"
raise "Get words failed!" unless app_session.response.status == 200 && res['data'].size >= 4
word_id = sample_word['id']

# 6. Test GET /api/v1/lessons/:lesson_id/quiz_questions (Safe questions)
puts "\n[6] Testing GET /api/v1/lessons/#{lesson_id}/quiz_questions..."
res = request_json(app_session, :get, "/api/v1/lessons/#{lesson_id}/quiz_questions")
puts "   Status: #{app_session.response.status}"
puts "   Questions count: #{res['data'].size}"
first_question = res['data'].first
puts "   Question text: #{first_question['question_text']}"
puts "   Options: #{first_question['options']}"
raise "Question leaked answer!" if first_question.key?('correct_answer')
raise "Get quiz questions failed!" unless app_session.response.status == 200

# 7. Test POST /api/v1/words/:word_id/study
puts "\n[7] Testing POST /api/v1/words/#{word_id}/study..."
res = request_json(app_session, :post, "/api/v1/words/#{word_id}/study", {}, auth_headers)
puts "   Status: #{app_session.response.status}"
puts "   Message: #{res['message']}"
puts "   Proficiency: #{res.dig('data', 'proficiency_level')}"
raise "Study word failed!" unless app_session.response.status == 200

# 8. Test POST /api/v1/quiz/submit
puts "\n[8] Testing POST /api/v1/quiz/submit..."
questions_for_lesson = Lesson.find(lesson_id).quiz_questions.to_a
submission_payload = {
  lesson_id: lesson_id,
  answers: [
    { question_id: questions_for_lesson[0].id.to_s, selected_answer: "C" },
    { question_id: questions_for_lesson[1].id.to_s, selected_answer: "A" },
    { question_id: questions_for_lesson[2].id.to_s, selected_answer: "B" }
  ]
}
res = request_json(app_session, :post, "/api/v1/quiz/submit", submission_payload, auth_headers)
puts "   Status: #{app_session.response.status}"
puts "   Score: #{res['score']}% (#{res['correct_count']}/#{res['total_questions']})"
puts "   Passed: #{res['passed']}"
puts "   Feedback count: #{res['feedback'].size}"
puts "   Feedback item 1 is_correct: #{res['feedback'][0]['is_correct']}"
raise "Quiz submission failed!" unless app_session.response.status == 200 && res['score'] == 100.0

# 9. Test GET /api/v1/quiz/history
puts "\n[9] Testing GET /api/v1/quiz/history..."
res = request_json(app_session, :get, "/api/v1/quiz/history", {}, auth_headers)
puts "   Status: #{app_session.response.status}"
puts "   Total attempts: #{res['total_count']}"
raise "Quiz history failed!" unless app_session.response.status == 200 && res['total_count'] >= 1

# 10. Test GET /api/v1/progress/summary
puts "\n[10] Testing GET /api/v1/progress/summary..."
res = request_json(app_session, :get, "/api/v1/progress/summary", {}, auth_headers)
puts "   Status: #{app_session.response.status}"
puts "   Stats: #{res.dig('data', 'study_stats')}"
puts "   Quiz Stats: #{res.dig('data', 'quiz_stats')}"
raise "Progress summary failed!" unless app_session.response.status == 200

# 11. Security Tests: 401 Unauthorized without token
puts "\n[11] Testing Security: Missing token on protected endpoint..."
request_json(app_session, :post, "/api/v1/quiz/submit", {})
puts "   Status: #{app_session.response.status} (Expected 401)"
raise "Security leak: allowed without token!" unless app_session.response.status == 401

# 12. Security Tests: 404 Not Found on non-existent resource
puts "\n[12] Testing 404 Not Found handling..."
request_json(app_session, :get, "/api/v1/lessons/nonexistentid123/words")
puts "   Status: #{app_session.response.status} (Expected 404)"
raise "404 handler failed!" unless app_session.response.status == 404

puts "\n== 100% CONTROLLER INTEGRATION TESTS PASSED! =="
