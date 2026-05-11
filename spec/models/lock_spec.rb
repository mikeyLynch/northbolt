require 'rails_helper'

RSpec.describe Lock, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:location) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end
end
