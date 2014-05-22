
Given /^I have connect to redis with namespace ([:\w]+)$/ do |namespace|
  r = Redis.new(:db => 10)
  @redis = Redis::Namespace.new(namespace.to_sym, :redis => r)
end

Given /^Current sets is empty$/ do
  @redis.flushdb
end

When /^Retrieve getchef cookbooks from remote$/ do
  @cookbooks = Getgetchef::Cookbooks.new(@redis)
end

Then /^Update staging sets on Redis$/ do
  @cookbooks.update_staging_sets
  @redis.scard(:staging_sets).should_not nil
  @redis.scard(:staging_sets).should > @cookbooks.staging_cookbooks.length
end

Then /^Raise exception if remote data is empty$/ do
  @cookbooks.staging_cookbooks = {}
  lambda{@cookbooks.update_staging_sets}.should raise_error(RuntimeError, "Caution: remote_data is empty.")
end

Given /^staging sets is exist$/ do
  @cookbooks = Getgetchef::Cookbooks.new(@redis)
  @cookbooks.update_staging_sets
end

Then /^current sets is filled by staging sets$/ do
  @cookbooks.current_sets.should_not == []
  @cookbooks.current_sets.sort.should == @cookbooks.staging_sets.sort
end

Then /^update current sets from staging$/ do
  @cookbooks.save_current_sets
  a = @redis.smembers(:current_sets)
  b = @redis.smembers(:staging_sets)
  a.sort.should == b.sort
end


Given /^I have current and staging sets on Redis$/ do
  @cookbooks = Getgetchef::Cookbooks.new(@redis)
  @cookbooks.update_staging_sets
  @cookbooks.save_current_sets
end

Then /^Raise exception if staging data is empty$/ do
  @redis.del :staging_sets
  lambda{@cookbooks.save_current_sets}.should raise_error(RuntimeError, "Caution: staging_set is empty.")
end


Given /^Some new cookbooks are available$/ do
  5.times do
    @redis.spop :current_sets
  end
end

Then /^I can pick up new cookbooks$/ do
  @cookbooks.find_new_cookbooks.length.should == 5
end

Given /^Some cookbooks are gone$/ do
  5.times do
    @redis.spop :staging_sets
  end
end

Then /^I can find out gone cookbooks$/ do
  @cookbooks.find_gone_cookbooks.length.should == 5
end


