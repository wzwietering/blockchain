require 'test/unit'

require_relative '../datastructures/queue.rb'

class TestQueue < Test::Unit::TestCase
  # Test adding an item to the queue
  def test_enqueue
    # Test the << operator
    queue = QueueDS.new
    queue << 5
    assert_equal(queue.length, 1)
    assert_equal(queue.peek, 5)
    
    # Test the enqueue method
    queue2 = QueueDS.new
    queue2.enqueue(5)
    assert_equal(queue2.length, 1)
    assert_equal(queue2.peek, 5)
    
    # Assert that enqueue and << are the same
    assert_equal(queue.length, queue2.length)
    assert_equal(queue.peek, queue2.peek)
  end

  def test_dequeue
    # Create test queue
    queue = QueueDS.new
    queue << 6

    # Test the dequeue
    result = queue.dequeue
    assert_equal(queue.length, 0)
    assert_equal(result, 6)
  end
end
