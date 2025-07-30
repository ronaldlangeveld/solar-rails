class Token < ApplicationRecord
  scope :latest, -> { order(created_at: :desc).first }
  
  def expired?
    expires < Time.current.to_i * 1000
  end
  
  def token_valid?
    access.present? && !expired?
  end
end