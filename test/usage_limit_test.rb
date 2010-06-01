require File.dirname(__FILE__) + '/test_helper'

class UsageLimitTest < Test::Unit::TestCase
  def setup
    storage.flushdb
  end

  def test_save
    UsageLimit.save(:service_id => '2001',
                    :plan_id    => '3001',
                    :metric_id  => '4001',
                    :month      => 1000000,
                    :week       => 300000,
                    :day        => 45000,
                    :hour       => 2000,
                    :minute     => 10)
    
    assert_equal '1000000',
                 storage.get('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/month')

    assert_equal '300000',
                 storage.get('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/week')

    assert_equal '45000',
                 storage.get('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/day')

    assert_equal '2000',
                 storage.get('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/hour')

    assert_equal '10',
                 storage.get('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/minute')
  end

  def test_load_all
    Metric.save(:service_id => 2001, :id => 4001, :name => 'hits')
    Metric.save(:service_id => 2001, :id => 4002, :name => 'transfer')

    storage.set('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/month', 1000)
    storage.set('usage_limit/service_id:2001/plan_id:3001/metric_id:4001/week',  500)
    storage.set('usage_limit/service_id:2001/plan_id:3001/metric_id:4002/month', 2100)

    usage_limits = UsageLimit.load_all(2001, 3001)
    assert_equal 3, usage_limits.count
  end

  def test_load_all_returns_empty_array_if_there_are_no_metrics
    usage_limits = UsageLimit.load_all(2001, 3001)
    assert usage_limits.empty?, 'Expected usage_limits to be empty'
  end

  def test_load_value
    UsageLimit.save(:service_id => 2001,
                    :plan_id    => 3001,
                    :metric_id  => 4001,
                    :hour       => 500)

    assert_equal 500, UsageLimit.load_value(2001, 3001, 4001, :hour)
  end

  def test_load_value_return_nil_if_the_usage_limit_does_not_exist
    assert_nil UsageLimit.load_value(2001, 3001, 4001, :hour)
  end

  def test_delete
    Metric.save(:service_id => 2001, :id => 4001, :name => 'hits')
    UsageLimit.save(:service_id => 2001,
                    :plan_id    => 3001,
                    :metric_id  => 4001,
                    :minute     => 10)

    UsageLimit.delete(2001, 3001, 4001, :minute)

    assert_nil UsageLimit.load_value(2001, 3001, 4001, :minute)

    usage_limits = UsageLimit.load_all(2001, 3001)
    assert usage_limits.none? { |limit| limit.metric_id == '4001' && limit.period == :minute }
  end

  def test_metric_name
    Metric.save(:service_id => 2001, :id => 4001, :name => 'hits')
    usage_limit = UsageLimit.new(:service_id => '2001',
                                 :plan_id    => '3001',
                                 :metric_id  => '4001')

    assert_equal 'hits', usage_limit.metric_name
  end

  def test_value_is_numeric
    Metric.save(:service_id => 2001, :id => 4001, :name => 'hits')
    UsageLimit.save(:service_id => '2001',
                    :plan_id    => '3001',
                    :metric_id  => '4001',
                    :month      => 1000000)
    usage_limit = UsageLimit.load_all(2001, 3001).first

    assert_equal 1000000, usage_limit.value
  end
end