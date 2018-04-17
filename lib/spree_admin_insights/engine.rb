module SpreeAdminInsights
  class Engine < Rails::Engine
    require 'spree/core'
    require 'wicked_pdf'
    require 'csv'

    isolate_namespace Spree
    engine_name 'spree_admin_insights'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    config.assets.precompile << 'spree/backend/override_pdf.css'

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    config.after_initialize do
    end
  end
end
