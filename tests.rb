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

  def test_lessons_has_many_readings
    lesson = Lesson.create(name:"Algerbra Basics", description: "Basic intro into the wonderful world of Algebra", outline: "See math, do math")
    reading1 = Reading.create(caption: "Back to Basics", url: "http://stopfailingatmaths.com", order_number: 1)
    reading2 = Reading.create(caption: "Linear Algebra", url: "http://sureyourereadyforthis.com", order_number: 2)

    assert lesson.readings << reading1
    assert lesson.readings << reading2

    assert_equal 2, lesson.readings.count
  end
end
