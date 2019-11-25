# frozen_string_literal: true

module Spree::Admin::BaseHelperDecorator
  def selected?(current_insight, insight)
    current_insight.eql?(insight)
  end

  def form_action(insight, insight_type)
    insight ? admin_insight_path(id: @report_name, type: insight_type) : 'javascript:void(0)'
  end

  def page_selector_options
    [5, 10, 20, 30, 45, 60]
  end

  def pdf_logo(image_path = Spree::Config[:logo])
    wicked_pdf_image_tag image_path, class: 'logo'
  end
end

::Spree::Admin::BaseHelper.prepend(Spree::Admin::BaseHelperDecorator)
