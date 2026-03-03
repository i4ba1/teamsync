require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TeamSync
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "UTC"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Use UUID as default primary key type
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Active Job adapter
    config.active_job.queue_adapter = :sidekiq

    # Action Cable allowed origins
    config.action_cable.allowed_request_origins = ENV.fetch("ACTION_CABLE_ALLOWED_REQUEST_ORIGINS", "http://localhost:3000").split(",")
    config.action_cable.disable_request_forgery_protection = true

    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins ENV.fetch("FRONTEND_URL", "http://localhost:3000")
        resource "*",
          headers: :any,
          methods: %i[get post put patch delete options head],
          credentials: true
      end
    end

    # Log to stdout
    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = config.log_formatter
      config.logger = ActiveSupport::TaggedLogging.new(logger)
    end
  end
end
