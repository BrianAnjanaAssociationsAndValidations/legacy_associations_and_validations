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

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  # The tasks will be divided as follows. "Associate" means to place has_many, belongs_to, has_and_belongs_to_many, etc
  # in the appropriate classes. "Validate" means to use validates in the appropriate classes with the appropriate parameters.

  # Person A:

  # Associate schools with terms (both directions).
  def test_schools_are_associated_with_terms
    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Sprint 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    term_two = Term.create(name: "Fall 2016 Cohort")

    assert school.terms << term
    assert school.terms << term_two

    assert_equal 2, school.terms.count
  end

  # Associate terms with courses (both directions).
  def test_terms_are_associated_with_courses
    term = Term.create(name: "Sprint 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JS6", color: "Mustard")

    assert term.courses << course
    assert term.courses << course_one

    assert_equal 2, term.courses.count
  end

  # If a term has any courses associated with it, the term should not be deletable.
  def test_if_a_term_has_courses_it_can_not_be_deleted
    term = Term.create(name: "Sprint 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
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


  # Validate that Lessons have names.


  # Validate that Readings must have an order_number, a lesson_id, and a url.


  # Validate that the Readings url must start with http:// or https://. Use a regular expression.


  # Validate that Courses have a course_code and a name.


  # Validate that the course_code is unique within a given term_id.


  # Validate that the course_code starts with three letters and ends with three numbers. Use a regular expression.

end
