class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :google_uid, uniqueness: true, allow_nil: true
end
