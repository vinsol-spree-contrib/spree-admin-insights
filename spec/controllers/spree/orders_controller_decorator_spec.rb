require 'spec_helper'

describe Spree::OrdersController do

  let(:order) { mock_model(Spree::Order, remaining_total: 1000, state: 'cart') }
  let(:user) { mock_model(Spree::User, store_credits_total: 500) }
  let(:checkout_event) { mock_model(Spree::CheckoutEvent) }

  before do
    allow(user).to receive(:orders).and_return(Spree::Order.all)
    allow(controller).to receive(:track_activity).and_return(checkout_event)
    allow(controller).to receive(:check_authorization).and_return(true)
    allow(controller).to receive(:current_order).and_return(order)
    allow(controller).to receive(:associate_user).and_return(true)
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:current_order).and_return(order)
  end

  describe '#edit' do

    def send_request
      get :edit, id: order.number
    end

    describe 'when return to cart' do

      context 'when return from a checkout step' do
        before do
          @checkout_steps = double('checkout_steps')
          allow(order).to receive(:checkout_steps).and_return(@checkout_steps)
          allow(@checkout_steps).to receive(:include?).and_return(true)
          request.env['HTTP_REFERER'] = 'test/address'
        end

        describe 'expects to receive' do
          it { expect(user).to receive(:orders).and_return(Spree::Order.all) }
          it { expect(controller).to receive(:track_activity).and_return(checkout_event) }
          it { expect(controller).to receive(:check_authorization).and_return(true) }
          it { expect(controller).to receive(:current_order).and_return(order) }
          it { expect(controller).to receive(:spree_current_user).and_return(user) }
          it { expect(controller).to receive(:current_order).and_return(order) }
          it { expect(controller).to receive(:associate_user).and_return(true) }
          it { expect(order).to receive(:checkout_steps).and_return(@checkout_steps) }
          it { expect(@checkout_steps).to receive(:include?).and_return(true) }

          after { send_request }
        end

        describe 'response' do
          before { send_request }
          it { expect(response).to have_http_status(200) }
        end

        describe 'assigns' do
          before { send_request }
          it { expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent) }
        end

      end

      context 'when a product is added' do
        before do
          checkout_steps = double('checkout_steps')
          allow(order).to receive(:checkout_steps).and_return(checkout_steps)
          allow(checkout_steps).to receive(:include?).and_return(false)
          request.env['HTTP_REFERER'] = 'test/my_test_product'
        end

        describe 'response' do
          before { send_request }
          it { expect(response).to have_http_status(200) }
        end

        describe 'assigns' do
          before { send_request }
          it { expect(controller.track_activity).to be_instance_of(Spree::CheckoutEvent) }
        end
      end

      context 'when return to cart from cart itself' do
        before do
          checkout_steps = double('checkout_steps')
          allow(order).to receive(:checkout_steps).and_return(checkout_steps)
          allow(checkout_steps).to receive(:include?).and_return(true)
          request.env['HTTP_REFERER'] = 'test/cart'
        end

        describe 'response' do
          before { send_request }
          it { expect(response).to have_http_status(200) }
        end

        describe 'expect to not receive' do
          it { expect(controller).not_to receive(:track_activity) }
          after { send_request }
        end
      end

    end
  end

  describe '#empty' do
    def send_request
      put :empty
    end

    before do
      allow(order).to receive(:empty!)
      request.env['HTTP_REFERER'] = 'test/cart'
    end

    describe 'expects to receive' do
      it { expect(user).to receive(:orders).and_return(Spree::Order.all) }
      it { expect(controller).to receive(:track_activity).and_return(checkout_event) }
      it { expect(controller).to receive(:check_authorization).and_return(true) }
      it { expect(controller).to receive(:current_order).and_return(order) }
      it { expect(controller).to receive(:spree_current_user).and_return(user) }
      it { expect(controller).to receive(:current_order).and_return(order) }
      it { expect(order).to receive(:empty!) }

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
