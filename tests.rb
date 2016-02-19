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
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
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
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
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
    # course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    # instructor1 = Instructor.create(name:)
  end

  def test_school_must_have_name
    school = School.create
    school2 = School.create(name: "The Iron Yard")
    refute School.exists?(school.id)
    assert School.exists?(school2.id)
  end

  def test_user_must_have_first_name_last_name_and_email
    user = User.create
    user2 = User.create(first_name: "Brian")
    user3 = User.create(first_name: "Brian", last_name: "Yarsawich")
    user4 = User.create(first_name: "Brian", last_name: "Yarsawich", email: "testing@test.com")
    refute User.exists?(user.id)
    refute User.exists?(user2.id)
    refute User.exists?(user3.id)
    assert User.exists?(user4.id)
  end

  def test_user_email_must_be_unique
    user = User.create(first_name: "Brian", last_name: "Yarsawich", email: "test@test.com")
    user2 = User.create(first_name: "John", last_name: "Doe", email: "test@test.com")
    assert User.exists?(user.id)
    refute User.exists?(user2.id)
  end

  # Associate schools with terms (both directions).
  def test_schools_are_associated_with_terms
    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    term_two = Term.create(name: "Fall 2016 Cohort")

    assert school.terms << term
    assert school.terms << term_two

    assert_equal 2, school.terms.count
  end

  # Associate terms with courses (both directions).
  def test_terms_are_associated_with_courses
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JS6", color: "Mustard")

    assert term.courses << course
    assert term.courses << course_one

    assert_equal 2, term.courses.count
  end

  # If a term has any courses associated with it, the term should not be deletable.
  def test_if_a_term_has_courses_it_can_not_be_deleted
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JS6", color: "Mustard")

    assert term.courses << course
    assert term.courses << course_one

    refute term.destroy
  end

  # Associate courses with course_students (both directions).
  def test_courses_are_associated_with_course_students
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    student = CourseStudent.create(student_id: 1)
    student_two = CourseStudent.create(student_id: 2)

    assert course.course_students << student
    assert course.course_students << student_two

    assert_equal 2, course.course_students.count
  end

  # If the course has any students associated with it, the course should not be deletable.
  def test_courses_are_associated_with_course_students
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    student = CourseStudent.create(student_id: 1)
    student_two = CourseStudent.create(student_id: 2)

    assert course.course_students << student
    assert course.course_students << student_two

    refute course.destroy
  end

  # Associate assignments with courses (both directions).
  def test_assignments_are_associated_with_courses
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    assignment = Assignment.create(name: "Battleship")
    assignment_two = Assignment.create(name: "Currency Converter")
    assignment_three = Assignment.create(name: "Time Entries")

    assert course.assignments << assignment
    assert course.assignments << assignment_two
    assert course.assignments << assignment_three

    assert_equal 3, course.assignments.count
  end

  # When a course is destroyed, its assignments should be automatically destroyed.
  def test_assignments_are_deleted_when_course_is_deleted
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    assignment = Assignment.create(name: "Battleship")
    assignment_two = Assignment.create(name: "Currency Converter")
    assignment_three = Assignment.create(name: "Time Entries")

    assert course.assignments << assignment
    assert course.assignments << assignment_two
    assert course.assignments << assignment_three

    assert course.destroy
    refute Assignment.exists?(assignment.id)
    refute Assignment.exists?(assignment_two.id)
    refute Assignment.exists?(assignment_three.id)
  end

  # Associate lessons with their pre_class_assignments (both directions).
  # def test_lessons_are_associated_with_their_pre_class_assignments
  #   lesson = Lesson.create(name:"Algebra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
  #   assignment = Assignment.create(name: "Variables")
  #   assignment_two = Assignment.create(name: "Equation")
  #   assignment_three = Assignment.create(name: "Polynomials")
  #
  #   assert lesson.pre_class_assignments << assignment
  #   assert lesson.pre_class_assignments << assignment_two
  #   assert lesson.pre_class_assignments << assignment_three
  #
  #   assert_equal 3, lesson.pre_class_assignments
  # end

  # Set up a School to have many courses through the school's terms.
  def test_school_can_have_many_courses_through_terms
    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Spring 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JS6", color: "Mustard")

    school.terms << term
    term.courses << course
    term.courses << course_one

    assert_equal 2, school.courses.count
  end

  # Validate that Lessons have names.
  def test_lesson_must_have_names
    lesson = Lesson.create(name:"Algebra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    lesson_two = Lesson.create(description: "Lorem ipsum")

    assert Lesson.exists?(lesson.id)
    refute Lesson.exists?(lesson_two.id)
  end

  # Validate that Readings must have an order_number, a lesson_id, and a url.
  def test_readings_must_have_order_number_lesson_id_and_url
    reading = Reading.create(order_number: 1234, lesson_id: 223, url: "http://www.google.com")
    reading_two = Reading.create(caption: "Back to Basics", url: "http://stopfailingatmaths.com", order_number: 1)
    reading_three = Reading.create()

    assert Reading.exists?(reading.id)
    refute Reading.exists?(reading_two.id)
    refute Reading.exists?(reading_three.id)
  end


  # Validate that the Readings url must start with http:// or https://. Use a regular expression.
  def test_readings_url_are_real
    reading = Reading.create(order_number: 1234, lesson_id: 223, url: "www.google.com")
    reading_two = Reading.create(order_number: 1, lesson_id: 254, url: "http://stopfailingatmaths.com")

    assert Reading.exists?(reading_two.id)
    refute Reading.exists?(reading.id)
  end

  # Validate that Courses have a course_code and a name.
  def test_courses_must_have_course_code_and_name
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    course_one = Course.create(course_code: "JS6", color: "Mustard")
    course_two = Course.create(name: "Front End", color: "Mustard")

    assert Course.exists?(course.id)
    refute Course.exists?(course_one.id)
    refute Course.exists?(course_two.id)
  end

  # Validate that the course_code is unique within a given term_id.
  def test_course_codes_are_unique_in_given_term
    course = Course.create(name: "Ruby on Rails", course_code: "1235", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "6789", color: "Mustard")
    course_two = Course.create(name: "Javascript", course_code: "6789", color: "Mustard")

    assert Course.exists?(course.id)
    assert Course.exists?(course_one.id)
    refute Course.exists?(course_two.id)
  end


  # Validate that the course_code starts with three letters and ends with three numbers. Use a regular expression.

end
