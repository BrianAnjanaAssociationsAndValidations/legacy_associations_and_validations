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

  def test_course_with_instructors_can_not_be_deleted
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    instructor1 = CourseInstructor.create(instructor_id: 1)
    instructor2 = CourseInstructor.create(instructor_id: 2)

    course.course_instructors << instructor1
    course.course_instructors << instructor2

    refute course.destroy
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

  def test_students_are_associated_with_course_students
    maths_student = CourseStudent.create
    english_student = CourseStudent.create
    user = User.create(first_name: "Brian", last_name: "Yarsawich", email: "testphotourl1@test.com", photo_url: "http://www.reddit.com")

    assert user.students << maths_student
    assert user.students << english_student

    assert_equal 2, user.students.count
  end

  def test_course_student_associated_with_assignment_grades
    student = CourseStudent.create(student_id: 10)
    grade = AssignmentGrade.new
    grade2 = AssignmentGrade.new

    assert student.assignment_grades << grade
    assert student.assignment_grades << grade2

    assert_equal 2, student.assignment_grades.count
  end

  def test_course_has_many_students_through_course_students
    student1 = User.create(first_name: "Brian", last_name: "Yarsawich", email: "testphotourl1@test.com", photo_url: "http://www.reddit.com")
    student2 = User.create(first_name: "John", last_name: "Doe", email: "testphotourl2@test.com", photo_url: "http://is.a.web.address.com")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet", term_id: 10)

    assert course.students << student1
    assert course.students << student2

    assert_equal 2, course.students.count
    assert_equal 2, course.course_students.count
  end

  def test_course_has_one_primary_instructor
    instructor1 = User.create(first_name: "Brian", last_name: "Yarsawich", email: "testphotourl1@test.com", photo_url: "http://www.reddit.com", instructor: true)
    instructor2 = User.create(first_name: "John", last_name: "Doe", email: "testphotourl2@test.com", photo_url: "http://is.a.web.address.com", instructor: true)
    instructor3 = User.create(first_name: "Da-Me", last_name: "Kim", email: "dame@email.com", instructor: true)
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet", term_id: 10)

    assert course.primary_instructor = instructor1
    assert course.instructors << instructor2

    assert_equal instructor1, course.primary_instructor

    assert course.primary_instructor = instructor3
    refute_equal instructor1, course.primary_instructor
    assert_equal instructor3, course.primary_instructor
  end

  def test_students_are_ordered_by_last_name_then_first_name
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet", term_id: 10)
    student1 = User.create(first_name: "Brian", last_name: "Yarsawich", email: "testphotourl1@test.com", photo_url: "http://www.reddit.com")
    student2 = User.create(first_name: "John", last_name: "Doe", email: "testphotourl2@test.com", photo_url: "http://is.a.web.address.com")
    student3 = User.create(first_name: "Da-Me", last_name: "Kim", email: "dame@email.com")
    student4 = User.create(first_name: "Kim", last_name: "Doe", email: "dame2@email.com")

    course.students << student1
    course.students << student2
    course.students << student3
    course.students << student4

    assert_equal [student2, student4, student3, student1], course.students
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

  # Associate course_instructors with instructors (who happen to be users)
  def test_course_instructors_are_associated_with_instructors
    mason = User.create(first_name: "Mason", last_name: "Matthews", email: "mason@email.com", photo_url: "https://avatars1.githubusercontent.com/u/5350842?v=3&s=400")
    class_one = CourseInstructor.create
    class_two = CourseInstructor.create

    class_one.instructor = mason
    class_two.instructor = mason

    class_one.save
    class_two.save

    assert_equal 2, mason.instructors.count
  end

  # Associate assignments with assignment_grades (both directions)
  def test_assignments_are_associated_with_assignment_grades
    assignment = Assignment.create(name: "Battleship", percent_of_grade: 10, course_id: 2)

    grade = AssignmentGrade.create(final_grade: "A")
    grade_two = AssignmentGrade.create(final_grade: "B")

    assert assignment.assignment_grades << grade
    assert assignment.assignment_grades << grade_two

    assert_equal 2, assignment.assignment_grades.count
  end

  # Set up a Course to have many instructors through the Course's course_instructors.
  def test_course_has_many_instructors_through_course_instructors
    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")
    mason = User.create(first_name: "Mason", last_name: "Matthews", email: "mason@email.com", photo_url: "https://avatars1.githubusercontent.com/u/5350842?v=3&s=400")
    da_me = User.create(first_name: "Da-Me", last_name: "Kim", email: "dame@email.com")

    course.instructors << mason
    course.instructors << da_me

    assert_equal 2, course.course_instructors.count
    assert_equal 2, course.instructors.count
  end

  # Validate that an Assignment's due_at field is not before the Assignment's active_at.
  def test_assignments_due_at_field_is_not_before_active_at_field
    battleship = Assignment.create(name: "Battleship", percent_of_grade: 10, course_id: 2)
    currency = Assignment.create(name: "Currency Converter", percent_of_grade: 10, course_id: 2)

    battleship.due_at = "2016-02-10"
    battleship.active_at = "2016-2-08"

    currency.due_at = "2016-02-14"
    currency.active_at = "2016-02-16"

    assert battleship.save
    refute currency.save
  end

  # A Course's assignments should be ordered by due_at, then active_at.
  def test_courses_assignments_are_ordered_by_due_at_then_active_at
    assignment = Assignment.new(name: "Battleship", percent_of_grade: 10, due_at: "2016-09-15", active_at: "2016-09-01")
    assignment_two = Assignment.new(name: "Currency", percent_of_grade: 10, due_at: "2016-09-05", active_at: "2016-09-01")
    assignment_three = Assignment.new(name: "Time entry", percent_of_grade: 10, due_at: "2016-09-15", active_at: "2016-08-01")

    course = Course.create(name: "Ruby on Rails", course_code: "ROR600", color: "Violet")

    course.assignments << assignment
    course.assignments << assignment_two
    course.assignments << assignment_three

    assert_equal 3, course.assignments.count

    assert_equal [assignment_two, assignment_three, assignment], course.assignments.to_a
  end

end
