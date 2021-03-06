# encoding: UTF-8

require File.expand_path("./helper", File.dirname(__FILE__))
require File.expand_path("./redis_mock", File.dirname(__FILE__))

include RedisMock::Helper

setup do
  init Redis.new(OPTIONS)
end

test "INFO" do |r|
  %w(last_save_time redis_version total_connections_received connected_clients total_commands_processed connected_slaves uptime_in_seconds used_memory uptime_in_days changes_since_last_save).each do |x|
    assert r.info.keys.include?(x)
  end
end

test "MONITOR" do |r|
  log = []

  t1 = Thread.new do
    Redis.new(OPTIONS).monitor do |line|
      log << line
      break if log.size == 3
    end
  end

  Thread.pass while log.empty? # Faster than sleep

  r.set "foo", "s1"

  t1.join

  assert log[-1][%q{(db 15) "set" "foo" "s1"}]
end

test "MONITOR returns value for break" do |r|
  result = r.monitor do |line|
    break line
  end

  assert result == "OK"
end

test "ECHO" do |r|
  assert "foo bar baz\n" == r.echo("foo bar baz\n")
end

test "DEBUG" do |r|
  r.set "foo", "s1"

  assert r.debug(:object, "foo").kind_of?(String)
end

test "SYNC" do |r|
  replies = {:sync => lambda { "+OK" }}

  redis_mock(replies) do
    redis = Redis.new(OPTIONS.merge(:port => 6380))

    assert "OK" == redis.sync
  end
end

