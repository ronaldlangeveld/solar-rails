class GridStatus < ApplicationRecord
  scope :latest, -> { order(created_at: :desc).first }
  scope :outages, -> { where(status: 0) }
  
  def power_on?
    status > 0
  end
end