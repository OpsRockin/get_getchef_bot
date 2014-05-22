require 'redis'
require 'redis-namespace'
require './lib/cookbooks'

GETCHEF_URL='http://community.opscode.com/cookbooks/'

task :default => [:test]

desc "run cucumber"
task :test do
  system("cucumber --color")
end

namespace :sidekiq do
  desc "start sidekiq"
  task :run do
    system("sidekiq -c 5 -r ./tasks/post_to_twitter_worker.rb")
  end

  desc "start sidekiq use localenv"
  task :local do
    require './env/local.rb'
    system("bundle exec sidekiq -v -c 5 -r ./tasks/post_to_twitter_worker.rb")
  end

  desc "pry use localenv"
  task :pry do
    require './env/local.rb'
    system("pry -r ./tasks/post_to_twitter_worker.rb")
  end
end


namespace :perform do

  def redis_setup
    r = Redis.new(:url => ENV['REDISTOGO_URL'])
    redis = Redis::Namespace.new(:getgetchef, :redis => r) 
    redis
  end

  desc "perform with local env"
  task :local do
    require './env/local.rb'
    require './tasks/post_to_twitter_worker'

    worker = Getgetchef::Cookbooks.new(redis_setup)
    worker.update_staging_sets

    # prepare to test
    redis_setup.spop :staging_sets
    redis_setup.spop :staging_sets
    redis_setup.spop :current_sets
    redis_setup.spop :current_sets

    # print old cookbook
    worker.find_gone_cookbooks.each do |cookbook|
      DummyWorker.perform_async("cookbook disappeared. #{cookbook}" ,["#test_tweet"])
      # PostWorker.perform_async("cookbook disappeared. #{cookbook}" ,["#test_tweet"])
    end

    # print new cookbook
    worker.find_new_cookbooks.each do |cookbook|
      data = split_cookbook(cookbook)
      DummyWorker.perform_async("Cookbook #{data[0]} version #{data[1]} has been uploaded. #{GETCHEF_URL}#{data[0]}" ,["#test_tweet"])
      PostWorker.perform_async("Cookbook #{data[0]} version #{data[1]} has been uploaded. #{GETCHEF_URL}#{data[0]}" ,["#test_tweet"])
    end

    worker.save_current_sets
    redis_setup.flushdb
  end

  desc "perform with heroku env"
  task :heroku do
    require './tasks/post_to_twitter_worker'

    worker = Getgetchef::Cookbooks.new(redis_setup)
    worker.update_staging_sets

    # print old cookbook
    worker.find_gone_cookbooks.each do |cookbook|
      data = split_cookbook(cookbook)
      ## Skip twiter gone cookbook
      # PostWorker.perform_async("cookbook disappeared. #{cookbook}" ,["#getchef"])
    end

    # print new cookbook
    worker.find_new_cookbooks.each do |cookbook|
      data = split_cookbook(cookbook)
      PostWorker.perform_async("Cookbook #{data[0]} version #{data[1]} has been uploaded. #{GETCHEF_URL}#{data[0]}" ,["#getgetchef"])
    end

    worker.save_current_sets
  end
end

def split_cookbook(cookbook)
  cookbook.split(':')
end
