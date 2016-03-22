require 'spec_helper'

describe Spree::Checkout::Event::Tracker do

  let(:actor) { create(:user) }
  let(:target) { create(:order) }
  let(:tracker) { Spree::Checkout::Event::Tracker.new(
                                              activity: 'test_activity',
                                              actor: actor,
                                              target: target,
                                              session_id: 'test_session_id',
                                              referrer: 'test_referrer',
                                              previous_state: 'test_previous_state',
                                              next_state: 'test_next_state'
                                            )
                }

  describe '#initialize' do
    it { expect(tracker.instance_variable_get(:@activity)).to eq('test_activity') }
    it { expect(tracker.instance_variable_get(:@actor)).to eq(actor) }
    it { expect(tracker.instance_variable_get(:@target)).to eq(target) }
    it { expect(tracker.instance_variable_get(:@referrer)).to eq('test_referrer') }
    it { expect(tracker.instance_variable_get(:@session_id)).to eq('test_session_id') }
    it { expect(tracker.instance_variable_get(:@previous_state)).to eq('test_previous_state') }
    it { expect(tracker.instance_variable_get(:@next_state)).to eq('test_next_state') }
  end

  describe '#track' do
    it 'should create CheckoutEvent instance' do
      expect(tracker.track).to be_instance_of(Spree::CheckoutEvent)
    end
  end

end
