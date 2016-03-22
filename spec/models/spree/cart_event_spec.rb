require 'spec_helper'

describe Spree::CartEvent do

  describe 'associations' do
    it { is_expected.to belong_to(:actor) }
    it { is_expected.to belong_to(:target) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_presence_of(:activity) }
    it { is_expected.to validate_presence_of(:target) }
    it { is_expected.to validate_presence_of(:actor) }
    it { is_expected.to validate_presence_of(:total) }
  end

end
