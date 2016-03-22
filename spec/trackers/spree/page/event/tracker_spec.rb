require 'spec_helper'

describe Spree::Page::Event::Tracker do

  let(:actor) { create(:user) }
  let(:target) { create(:order) }
  let(:tracker) { Spree::Page::Event::Tracker.new(
                                              activity: 'test_activity',
                                              actor: actor,
                                              target: target,
                                              session_id: 'test_session_id',
                                              referrer: 'test_referrer',
                                              search_keywords: 'test_search_keywords',
                                              next_state: 'test_next_state'
                                            )
                }

  describe '#initialize' do
    it { expect(tracker.instance_variable_get(:@activity)).to eq('test_activity') }
    it { expect(tracker.instance_variable_get(:@actor)).to eq(actor) }
    it { expect(tracker.instance_variable_get(:@target)).to eq(target) }
    it { expect(tracker.instance_variable_get(:@referrer)).to eq('test_referrer') }
    it { expect(tracker.instance_variable_get(:@session_id)).to eq('test_session_id') }
    it { expect(tracker.instance_variable_get(:@search_keywords)).to eq('test_search_keywords') }
  end

  describe '#track' do
    it 'should create PageEvent object' do
      expect(tracker.track).to be_instance_of(Spree::PageEvent)
    end
  end

end
