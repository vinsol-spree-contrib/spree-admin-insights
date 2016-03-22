require 'spec_helper'

describe Spree::Cart::Event::Tracker do

  let(:actor) { create(:order) }
  let(:target) { create(:line_item) }
  let(:tracker) { Spree::Cart::Event::Tracker.new(
                                              activity: 'test_activity',
                                              actor: actor,
                                              target: target,
                                              session_id: 'test_session_id',
                                              referrer: 'test_referrer',
                                              quantity: 'test_quantity',
                                              total: 'test_total'
                                            )
                }

  describe '#initialize' do
    it { expect(tracker.instance_variable_get(:@activity)).to eq('test_activity') }
    it { expect(tracker.instance_variable_get(:@actor)).to eq(actor) }
    it { expect(tracker.instance_variable_get(:@target)).to eq(target) }
    it { expect(tracker.instance_variable_get(:@referrer)).to eq('test_referrer') }
    it { expect(tracker.instance_variable_get(:@session_id)).to eq('test_session_id') }
    it { expect(tracker.instance_variable_get(:@quantity)).to eq('test_quantity') }
    it { expect(tracker.instance_variable_get(:@total)).to eq('test_total') }
  end

  describe '#track' do
    it 'should create CartEvent object' do
      expect(tracker.track).to be_instance_of(Spree::CartEvent)
    end
  end

  describe '#changed_quantity' do

    before do
      target.quantity = 8
      target.save
      @previous_quantity_changes = target.previous_changes[:quantity].map(&:to_i)
    end

    it 'should return previous quantity changes' do
      expect(tracker.changed_quantity(@previous_quantity_changes)).to be_instance_of(Fixnum)
    end
  end

  describe '#activity' do
    context 'when item is added' do
      before do
        @changed_quantity = target.quantity
      end
      it { expect(tracker.activity(@changed_quantity, target)).to eq(:add) }
    end

    context 'when item is removed' do
      before do
        target.quantity = 0
        target.save
        @changed_quantity = -1
      end
      it { expect(tracker.activity(@changed_quantity, target)).to eq(:remove) }
    end

    context 'when item is updated' do
      it { expect(tracker.activity(7, target)).to eq(:update) }
    end

  end

end
