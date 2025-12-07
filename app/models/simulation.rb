class Simulation < ApplicationRecord
  belongs_to :user
  enum status: { pending: "pending", running: "running", finished: "finished" }, _default: "pending"

  validates :generation, :rows, :cols, presence: true
  validates :rows, :cols, numericality: { greater_than: 0 }
end
