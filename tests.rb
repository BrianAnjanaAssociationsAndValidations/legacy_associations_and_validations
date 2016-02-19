# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

ActiveRecord::Migration.verbose = false
# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.

# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def setup
    begin ApplicationMigration.migrate(:up); rescue; end
  end

  def teardown
    ApplicationMigration.migrate(:down)
  end

  def test_truth
    assert true
  end

  def test_lessons_has_many_readings
    lesson = Lesson.create(name:"Algerbra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    reading1 = Reading.create(caption: "Back to Basics", url: "http://stopfailingatmaths.com", order_number: 1)
    reading2 = Reading.create(caption: "Linear Algebra", url: "http://sureyourereadyforthis.com", order_number: 2)

    assert lesson.readings << reading1
    assert lesson.readings << reading2

    assert_equal 2, lesson.readings.count
  end

  def test_readings_are_deleted_if_parent_lesson_is_deleted
    lesson = Lesson.create(name:"Algerbra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    reading1 = Reading.create(caption: "Back to Basics", url: "http://stopfailingatmaths.com", order_number: 1)
    reading2 = Reading.create(caption: "Linear Algebra", url: "http://sureyourereadyforthis.com", order_number: 2)

    lesson.readings << reading1
    lesson.readings << reading2

    lesson.destroy
    refute Reading.exists?(reading1.id)
    refute Reading.exists?(reading2.id)
  end

  def test_courses_has_many_lessons
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    lesson1 = Lesson.create(name: "Algerbra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    lesson2 = Lesson.create(name: "Basketweaving", description: "For all our sports stars", outline: "Weave a basket and get an A")

    assert course.lessons << lesson1
    assert course.lessons << lesson2

    assert 2, course.lessons.count
  end

  def test_lessons_are_deleted_if_parent_course_is_deleted
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    lesson1 = Lesson.create(name: "Algerbra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    lesson2 = Lesson.create(name: "Basketweaving", description: "For all our sports stars", outline: "Weave a basket and get an A")

    course.lessons << lesson1
    course.lessons << lesson2

    course.destroy

    refute Lesson.exists?(lesson1.id)
    refute Lesson.exists?(lesson2.id)
  end

  def test_course_has_many_readings_through_lessons
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    lesson1 = Lesson.create(name: "Algerbra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    lesson2 = Lesson.create(name: "Basketweaving", description: "For all our sports stars", outline: "Weave a basket and get an A")
    reading1 = Reading.create(caption: "Back to Basics", url: "http://stopfailingatmaths.com", order_number: 1)
    reading2 = Reading.create(caption: "Linear Algebra", url: "http://sureyourereadyforthis.com", order_number: 2)

    course.lessons << lesson1
    course.lessons << lesson2
    lesson1.readings << reading1
    lesson1.readings << reading2

    assert_equal 2, course.readings.count
  end

  def test_course_has_many_course_instructors
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    instructor1 = CourseInstructor.create(instructor_id: 1)
    instructor2 = CourseInstructor.create(instructor_id: 2)

    assert course.course_instructors << instructor1
    assert course.course_instructors << instructor2

    assert 2, course.course_instructors.count
  end

  def test_lessons_are_associated_with_their_in_class_assignments
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    lesson = Lesson.create(name:"Algebra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    assignment = Assignment.create(name: "Variables", percent_of_grade: 10)

    course.assignments << assignment
    assert assignment.in_class_assignments << lesson

    assert_equal Assignment.find(assignment.id), lesson.in_class_assignment
  end

  def test_school_must_have_name
    school = School.new
    school2 = School.new(name: "The Iron Yard")
    refute school.save
    assert school2.save
  end

  #Validate that Terms must have name, starts_on, ends_on, and school_id.
  def test_terms_validation
    school = School.create(name: "The Iron Yard")
    term = Term.new(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    term_two = Term.new(name: "Fall 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    school.terms << term
    assert term.save
    refute term_two.save
  end

  def test_user_must_have_first_name_last_name_and_email
    user = User.new
    user2 = User.new(first_name: "Brian")
    user3 = User.new(first_name: "Brian", last_name: "Yarsawich")
    user4 = User.new(first_name: "Brian", last_name: "Yarsawich", email: "testing@test.com")
    refute user.save
    refute user2.save
    refute user3.save
    assert user4.save
  end

  def test_user_email_must_be_unique
    user = User.new(first_name: "Brian", last_name: "Yarsawich", email: "test@test.com")
    user2 = User.new(first_name: "John", last_name: "Doe", email: "test@test.com")
    assert user.save
    refute user2.save
  end

  def test_user_email_must_be_formated_correctly
    user = User.new(first_name: "Brian", last_name: "Yarsawich", email: "testemailformat@test.com")
    user2 = User.new(first_name: "John", last_name: "Doe", email: "I am 31337 Haxz0r")
    assert user.save
    refute user2.save
  end

  def test_user_photo_url_must_start_as_web_address
    user = User.new(first_name: "Brian", last_name: "Yarsawich", email: "testphotourl1@test.com", photo_url: "http://www.reddit.com")
    user2 = User.new(first_name: "John", last_name: "Doe", email: "testphotourl2@test.com", photo_url: "not.a.web.address.com")
    assert user.save
    refute user2.save
  end

  def test_validate_assignments
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    assign1 = Assignment.new
    assign2 = Assignment.new(name: "Midterm")
    assign3 = Assignment.new(name: "Final", percent_of_grade: 20)
    assign4 = Assignment.new(name: "Quiz1", percent_of_grade: 5.2)

    course.assignments << assign4

    refute assign1.save
    refute assign2.save
    refute assign3.save
    assert assign4.save
  end

  def test_assignments_have_unique_name_for_each_course_id
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JST600", color: "Mustard")
    assign1 = Assignment.new(name: "Final", percent_of_grade: 20)
    assign2 = Assignment.new(name: "Quiz1", percent_of_grade: 5.2)
    assign3 = Assignment.new(name: "Quiz1", percent_of_grade: 20.2)

    assert course.assignments << assign1
    assert course.assignments << assign2
    refute course.assignments << assign3
    assert course_one.assignments << assign3
  end

  # Associate schools with terms (both directions).
  def test_schools_are_associated_with_terms
    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    term_two = Term.create(name: "Fall 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")

    assert school.terms << term
    assert school.terms << term_two

    assert_equal 2, school.terms.count
  end

  # Associate terms with courses (both directions).
  def test_terms_are_associated_with_courses
    school = School.create(name: "The Iron Yard")
    term = Term.new(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.new(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    course_one = Course.new(name: "Front End", course_code: "JST600", color: "Mustard")
    school.terms << term
    assert term.courses << course
    assert term.courses << course_one

    assert_equal 2, term.courses.count
  end

  # If a term has any courses associated with it, the term should not be deletable.
  def test_if_a_term_has_courses_it_can_not_be_deleted
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JST600", color: "Mustard")

    assert term.courses << course
    assert term.courses << course_one

    refute term.destroy
  end

  # Associate courses with course_students (both directions).
  def test_courses_are_associated_with_course_students
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    student = CourseStudent.create(student_id: 1)
    student_two = CourseStudent.create(student_id: 2)

    assert course.course_students << student
    assert course.course_students << student_two

    assert_equal 2, course.course_students.count
  end

  # If the course has any students associated with it, the course should not be deletable.
  def test_courses_are_associated_with_course_students
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    student = CourseStudent.create(student_id: 1)
    student_two = CourseStudent.create(student_id: 2)

    assert course.course_students << student
    assert course.course_students << student_two

    refute course.destroy
  end

  # Associate assignments with courses (both directions).
  def test_assignments_are_associated_with_courses
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    assignment = Assignment.create(name: "Battleship", percent_of_grade: 10)
    assignment_two = Assignment.create(name: "Currency Converter", percent_of_grade: 10)
    assignment_three = Assignment.create(name: "Time Entries", percent_of_grade: 10)

    assert course.assignments << assignment
    assert course.assignments << assignment_two
    assert course.assignments << assignment_three

    assert_equal 3, course.assignments.count
  end

  # When a course is destroyed, its assignments should be automatically destroyed.
  def test_assignments_are_deleted_when_course_is_deleted
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    assignment = Assignment.create(name: "Battleship", percent_of_grade: 10)
    assignment_two = Assignment.create(name: "Currency Converter", percent_of_grade: 10)
    assignment_three = Assignment.create(name: "Time Entries", percent_of_grade: 10)

    assert course.assignments << assignment
    assert course.assignments << assignment_two
    assert course.assignments << assignment_three

    assert course.destroy
    refute Assignment.exists?(assignment.id)
    refute Assignment.exists?(assignment_two.id)
    refute Assignment.exists?(assignment_three.id)
  end

  # Associate lessons with their pre_class_assignments (both directions).
  def test_lessons_are_associated_with_their_pre_class_assignments
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    lesson = Lesson.create(name:"Algebra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    assignment = Assignment.create(name: "Variables", percent_of_grade: 10)

    course.assignments << assignment
    assert lesson.pre_class_assignment = assignment

    assert_equal Assignment.find(assignment.id), lesson.pre_class_assignment
  end

  # Set up a School to have many courses through the school's terms.
  def test_school_can_have_many_courses_through_terms
    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JST600", color: "Mustard")

    school.terms << term
    term.courses << course
    term.courses << course_one

    assert_equal 2, school.courses.count
  end

  # Validate that Lessons have names.
  def test_lesson_must_have_names
    lesson = Lesson.new(name:"Algebra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    lesson_two = Lesson.new(description: "Lorem ipsum")

    assert lesson.save
    refute lesson_two.save
  end

  # Validate that Readings must have an order_number, a lesson_id, and a url.
  def test_readings_must_have_order_number_lesson_id_and_url
    reading = Reading.new(order_number: 1234, lesson_id: 223, url: "http://www.google.com")
    reading_two = Reading.new(caption: "Back to Basics", url: "http://stopfailingatmaths.com", order_number: 1)
    reading_three = Reading.new()

    assert reading.save
    refute reading_two.save
    refute reading_three.save
  end

  # Validate that the Readings url must start with http:// or https://. Use a regular expression.
  def test_readings_url_are_real
    reading = Reading.new(order_number: 1234, lesson_id: 223, url: "www.google.com")
    reading_two = Reading.new(order_number: 1, lesson_id: 254, url: "http://stopfailingatmaths.com")
    reading_three = Reading.new(order_number: 3, lesson_id: 274, url: "56672http://stopfailingatmaths.com")

    assert reading_two.save
    refute reading.save
    refute reading_three.save
  end

  # Validate that Courses have a course_code and a name.
  def test_courses_must_have_course_code_and_name
    course = Course.new(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    course_one = Course.new(course_code: "JST600", color: "Mustard")
    course_two = Course.new(name: "Front End", color: "Mustard")

    assert course.save
    refute course_one.save
    refute course_two.save
  end

  # Validate that the course_code is unique within a given term_id.
  def test_course_codes_are_unique_in_given_term
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22", school_id: 3)
    term_two = Term.create(name: "Fall 2016 Cohort", starts_on: "2016-09-01", ends_on: "2016-011-22", school_id: 5)

    course = Course.create(name: "Ruby on Rails", course_code: "ABC123", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "DEF456", color: "Mustard")
    course_two = Course.create(name: "Javascript", course_code: "DEF456", color: "Mustard")

    assert term.courses << course
    assert term.courses << course_one
    refute term.courses << course_two
    assert term_two.courses << course_two
  end

  # Validate that the course_code starts with three letters and ends with three numbers. Use a regular expression.
  def test_course_code_format
    course = Course.new(name: "Ruby on Rails", course_code: "ABC123", color: "Violet")
    course_one = Course.new(name: "Front End", course_code: "DE456", color: "Mustard")
    course_two = Course.new(name: "Javascript", course_code: "DEF6", color: "Mustard")

    assert course.save
    refute course_one.save
    refute course_two.save
  end

end
