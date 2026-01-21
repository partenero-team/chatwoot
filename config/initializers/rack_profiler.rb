# frozen_string_literal: true

if Rails.env.development? && ENV['DISABLE_MINI_PROFILER'].blank?
  require 'rack-mini-profiler'

  # Disable mini-profiler for swagger routes before initialization
  Rack::MiniProfiler.config.skip_paths ||= []
  Rack::MiniProfiler.config.skip_paths << '/swagger'
  Rack::MiniProfiler.config.skip_paths << %r{^/swagger}

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
