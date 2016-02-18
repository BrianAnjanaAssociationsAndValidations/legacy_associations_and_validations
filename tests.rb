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

  # Associate terms with courses (both directions). If a term has any courses associated with it, the term should not be deletable.
  def test_terms_are_associated_with_courses
    term = Term.create(name: "Sprint 2016 Cohort", starts_on: "2016-02-01", ends_on: "2016-05-22")
    course = Course.create(name: "Ruby on Rails", course_code: "ROR6", color: "Violet")
    course_one = Course.create(name: "Front End", course_code: "JS6", color: "Mustard")

    assert term.courses << course
    assert term.courses << course_one

    assert_equal 2, term.courses.count
  end

  # Associate courses with course_students (both directions). If the course has any students associated with it, the course should not be deletable.


  # Associate assignments with courses (both directions). When a course is destroyed, its assignments should be automatically destroyed.


  # Associate lessons with their pre_class_assignments (both directions).


  # Set up a School to have many courses through the school's terms.


  # Validate that Lessons have names.


  # Validate that Readings must have an order_number, a lesson_id, and a url.


  # Validate that the Readings url must start with http:// or https://. Use a regular expression.


  # Validate that Courses have a course_code and a name.


  # Validate that the course_code is unique within a given term_id.


  # Validate that the course_code starts with three letters and ends with three numbers. Use a regular expression.

end
