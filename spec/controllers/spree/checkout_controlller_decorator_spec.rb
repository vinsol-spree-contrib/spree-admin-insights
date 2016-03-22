require 'spec_helper'

describe Spree::CheckoutController do

  let(:order) { mock_model(Spree::Order, remaining_total: 1000, state: 'cart') }
  let(:user) { mock_model(Spree::User, store_credits_total: 500) }
  let(:checkout_event) { mock_model(Spree::CheckoutEvent) }

  before do
    allow(user).to receive(:orders).and_return(Spree::Order.all)
    allow(controller).to receive(:track_activity).and_return(checkout_event)
    allow(controller).to receive(:ensure_order_not_completed).and_return(true)
    allow(controller).to receive(:ensure_checkout_allowed).and_return(true)
    allow(controller).to receive(:ensure_sufficient_stock_lines).and_return(true)
    allow(controller).to receive(:ensure_valid_state).and_return(true)
    allow(controller).to receive(:associate_user).and_return(true)
    allow(controller).to receive(:check_authorization).and_return(true)
    allow(controller).to receive(:current_order).and_return(order)
    allow(controller).to receive(:setup_for_current_state).and_return(true)
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(order).to receive(:can_go_to_state?).and_return(false)
  end

  describe '#edit' do

    def send_request(state)
      get :edit, state: state
    end

    before do
      allow(order).to receive(:state=).and_return("address")
    end

    context 'when previous state is different than next state' do

      describe 'expects to receive' do
        it { expect(user).to receive(:orders).and_return(Spree::Order.all) }
        it { expect(controller).to receive(:track_activity).and_return(checkout_event) }
        it { expect(controller).to receive(:ensure_order_not_completed).and_return(true) }
        it { expect(controller).to receive(:ensure_checkout_allowed).and_return(true) }
        it { expect(controller).to receive(:ensure_sufficient_stock_lines).and_return(true) }
        it { expect(controller).to receive(:ensure_valid_state).and_return(true) }
        it { expect(controller).to receive(:associate_user).and_return(true) }
        it { expect(controller).to receive(:check_authorization).and_return(true) }
        it { expect(controller).to receive(:current_order).and_return(order) }
        it { expect(controller).to receive(:setup_for_current_state).and_return(true) }
        it { expect(controller).to receive(:spree_current_user).and_return(user) }
        it { expect(order).to receive(:can_go_to_state?).and_return(false) }
        it { expect(order).to receive(:state=).and_return("address") }

        after { send_request('address') }
      end

      describe 'response' do
        before { send_request('address') }
        it { expect(response).to have_http_status(200) }
      end

      describe 'assigns' do
        before { send_request('address') }
        it { expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent) }
      end

    end

    context 'when previous state is same as next state' do
      before { request.env['HTTP_REFERER'] = 'test/cart' }

      describe 'response' do
        before { send_request('cart') }
        it { expect(response).to have_http_status(200) }
      end

      describe 'expect not to receive' do
        it { expect(controller).not_to receive(:track_activity) }
        after { send_request('cart') }
      end
    end

  end

  describe '#update' do

    def send_request
      patch :update, state: order.state
    end

    before do
      allow(order).to receive(:update_from_params).and_return(true)
      allow(order).to receive(:temporary_address=).and_return(true)
      allow(order).to receive(:state=).and_return("complete")
      allow(order).to receive(:next).and_return(true)
      allow(order).to receive(:completed?).and_return(true)
      request.env['HTTP_REFERER'] = 'test/confirm'
    end

    describe 'expects to receive' do
      it { expect(user).to receive(:orders).and_return(Spree::Order.all) }
      it { expect(controller).to receive(:track_activity).and_return(checkout_event) }
      it { expect(controller).to receive(:ensure_order_not_completed).and_return(true) }
      it { expect(controller).to receive(:ensure_checkout_allowed).and_return(true) }
      it { expect(controller).to receive(:ensure_sufficient_stock_lines).and_return(true) }
      it { expect(controller).to receive(:ensure_valid_state).and_return(true) }
      it { expect(controller).to receive(:associate_user).and_return(true) }
      it { expect(controller).to receive(:check_authorization).and_return(true) }
      it { expect(controller).to receive(:current_order).and_return(order) }
      it { expect(controller).to receive(:setup_for_current_state).and_return(true) }
      it { expect(controller).to receive(:spree_current_user).and_return(user) }
      it { expect(order).to receive(:can_go_to_state?).and_return(false) }
      it { expect(order).to receive(:update_from_params).and_return(true) }
      it { expect(order).to receive(:temporary_address=).and_return(true) }
      it { expect(order).to receive(:state=).and_return("complete") }
      it { expect(order).to receive(:next).and_return(true) }
      it { expect(order).to receive(:completed?).and_return(true) }

      after { send_request }
    end

    describe 'assigns' do
      before { send_request }
      it { expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent) }
    end

    describe 'response' do
      before { send_request }
      it { expect(response).to have_http_status(302) }
    end

  end

end
