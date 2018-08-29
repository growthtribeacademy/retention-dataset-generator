# Start up sidekiq via
# sidekiq -r ./server_sidekiq.rb
#

require 'sidekiq'
require 'sidekiq-status'
require 'redis'
require 'redis-namespace'



Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'jobs', '*.rb') ].each {|file|  require file}

# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'growthtribe-retention-dataset', url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379' }


  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware
  end

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end