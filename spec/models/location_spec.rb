require 'rails_helper'

RSpec.describe Location, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:locks).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end
end
