require 'spec_helper'

describe Spree::Event::Tracker do

  let(:actor) { create(:user) }
  let(:target) { create(:order) }
  let(:tracker) { Spree::Event::Tracker.new(
                                              activity: 'test_activity',
                                              actor: actor,
                                              target: target,
                                              session_id: 'test_session_id',
                                              referrer: 'test_referrer'
                                            )
                }

  describe '#initialize' do
    it { expect(tracker.instance_variable_get(:@activity)).to eq('test_activity') }
    it { expect(tracker.instance_variable_get(:@actor)).to eq(actor) }
    it { expect(tracker.instance_variable_get(:@target)).to eq(target) }
    it { expect(tracker.instance_variable_get(:@referrer)).to eq('test_referrer') }
    it { expect(tracker.instance_variable_get(:@session_id)).to eq('test_session_id') }
  end

  describe '#track' do
    it 'should raise exception' do
      expect{ tracker.track }.to raise_error('#track should be implemented in a sub-class of Event::Tracker')
    end
  end

end
