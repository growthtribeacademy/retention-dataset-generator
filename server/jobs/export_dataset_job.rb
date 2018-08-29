require 'sidekiq'



require __dir__ + '/../lib/generator'

class ExportDatasetJob
  include Sidekiq::Worker

  def perform( api_key )
    Dataset.new(api_key).to_mixpanel
  end
end