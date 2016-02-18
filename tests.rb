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
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

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
end
