require File.dirname(__FILE__) + '/test_helper'

class MetricTest < Test::Unit::TestCase
  def setup
    storage.flushdb
  end

  def test_save
    metric = Metric.new(:service_id => 1001, :id => 2001, :name => 'hits')
    metric.save
    
    assert_equal '2001',   storage.get("metric/service_id:1001/name:hits/id")
    assert_equal 'hits',   storage.get("metric/service_id:1001/id:2001/name")
    assert_equal ['2001'], storage.smembers("metrics/service_id:1001/ids")

    assert_nil storage.get("metric/service_id:1001/id:2001/parent_id")
  end

  def test_save_with_children
    metric = Metric.new(:service_id => 1001, :id => 2001, :name => 'hits')
    metric.children << Metric.new(:id => 2002, :name => 'search_queries')
    metric.save
    
    assert_equal '2001', storage.get("metric/service_id:1001/name:hits/id")
    assert_equal 'hits', storage.get("metric/service_id:1001/id:2001/name")
    assert_nil           storage.get("metric/service_id:1001/id:2001/parent_id")
    
    assert_equal '2002',           storage.get("metric/service_id:1001/name:search_queries/id")
    assert_equal 'search_queries', storage.get("metric/service_id:1001/id:2002/name")
    assert_equal '2001',           storage.get("metric/service_id:1001/id:2002/parent_id")
    
    assert_equal ['2001', '2002'], storage.smembers("metrics/service_id:1001/ids").sort
  end

  def test_load
    Metric.save(:service_id => 1001, :id => 2001, :name => 'foos')

    metric = Metric.load(1001, 2001)
    assert_not_nil metric
    assert_equal '2001', metric.id
    assert_equal '1001', metric.service_id
    assert_equal 'foos', metric.name
  end
  
  def test_load_all_ids
    Metric.save(:service_id => 1001, :id => 2001, :name => 'foos')
    Metric.save(:service_id => 1001, :id => 2002, :name => 'bars')
    Metric.save(:service_id => 1002, :id => 2003, :name => 'bazs')

    assert_equal ['2001', '2002'], Metric.load_all_ids(1001)
  end

  def test_load_name
    Metric.save(:service_id => 1001, :id => 2001, :name => 'bananas')
    assert_equal 'bananas', Metric.load_name(1001, 2001)
  end

  def test_load_id
    Metric.save(:service_id => 1001, :id => 2002, :name => 'monkeys')
    assert_equal '2002', Metric.load_id(1001, 'monkeys')
  end

  def test_delete
    Metric.save(:service_id => 1001, :id => 2003, :name => 'donkeys')
    Metric.delete(1001, 2003)

    assert_nil Metric.load(1001, 2003)
    assert_nil Metric.load_id(1001, 'donkeys')
    assert !Metric.load_all_ids(1001).include?('2003')
  end
end
