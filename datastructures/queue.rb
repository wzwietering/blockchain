# This class implements the queue datastructure
# The class name is chosen to prevent a naming collision with Thread::Queue

class QueueDS
  def initialize
    @queue = Array.new
  end

  # Retrieve the last item from the queue
  def dequeue
    @queue.pop
  end

  # Items are added to the front of the list 
  def enqueue(item)
    @queue.unshift(item)
  end

  alias_method :<<, :enqueue

  # Get the last item without removing it
  def peek
    @queue[-1]
  end

  def length
    @queue.length
  end
end
