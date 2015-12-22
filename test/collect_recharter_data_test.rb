require "minitest/autorun"
require_relative "../collect_recharter_data"

=begin
ruby -Ilib:test test/collect_recharter_data_test.rb
=end

describe CollectRecharterData do
  before do
    @crdata = CollectRecharterData.new
  end
end
