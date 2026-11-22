# == Schema Information
#
# Table name: heartbeats
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_heartbeats_on_name  (name) UNIQUE
#
class Heartbeat < ApplicationRecord
end
