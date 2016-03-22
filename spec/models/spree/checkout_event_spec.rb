require 'spec_helper'

describe Spree::CheckoutEvent do

  describe 'associations' do
    it { is_expected.to belong_to(:actor) }
    it { is_expected.to belong_to(:target) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:session_id) }
    it { is_expected.to validate_presence_of(:activity) }
    it { is_expected.to validate_presence_of(:target) }
  end

end
