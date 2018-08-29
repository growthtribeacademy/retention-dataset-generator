require 'sidekiq'
require 'redis'
require 'redis-namespace'
require 'erb'
require 'sinatra'


## SIDEKIQ QUEUE JOB
Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'server', 'jobs', '*.rb') ].each {|file|  require file}

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'growthtribe-retention-dataset'}
end

CURRENT_FILE_PATH = File.expand_path(File.dirname(__FILE__))

get '/' do
  @template = File.read(File.join(CURRENT_FILE_PATH, 'server', 'views', 'index.html.erb'))
  @notice = 'Your Dataset is on the way' if params['perform']

  [200, {"Content-Type" => 'text/html'}, [ERB.new(@template).result( binding )]]
end


post '/export' do
  location = '/'

  if params['api_key']
    ExportDatasetJob.perform_async(params['api_key'])
    location << '?perform=success'
  end

  [301, {'Location' => location, 'Content-Type' => 'text/html'}, ['Moved Permanently']]
end