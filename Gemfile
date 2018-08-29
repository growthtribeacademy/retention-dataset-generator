source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.4'

gem 'rails'
gem 'puma'
gem 'activesupport'
gem 'rack'
gem 'redis'
gem 'redis-namespace'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'mixpanel-ruby'
gem 'faker'
gem 'sinatra'