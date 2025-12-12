# == Schema Information
#
# Table name: pipeline_stages
#
#  id         :bigint           not null, primary key
#  color      :string
#  name       :string
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_account_id  (account_id)
#  index_pipeline_stages_on_name        (name)
#  index_pipeline_stages_on_position    (position)
#
class PipelineStage < ApplicationRecord
  belongs_to :account
  has_many :contacts, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :account_id, presence: true

  default_scope { order(position: :asc) }
end
