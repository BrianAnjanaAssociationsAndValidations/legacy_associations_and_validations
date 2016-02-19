class Reading < ActiveRecord::Base
  belongs_to :lesson

  validates :lesson_id, presence: true
  validates :order_number, presence: true
  validates :url, presence: true, format: { with: /(http)s?:\/\/.*/}

  default_scope { order('order_number') }

  scope :pre, -> { where("before_lesson = ?", true) }
  scope :post, -> { where("before_lesson != ?", true) }

  def clone
    dup
  end
end
