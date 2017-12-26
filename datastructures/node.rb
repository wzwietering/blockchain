require 'digest'

class Node
  attr_reader :left, :right, :hash

  # A node is two nodes or leafs and a hash
  def initialize(left, right=nil)
    @left = left
    # Uneven trees have no right node, so we copy the left one to balance the tree
    @right = (right or left)
    # The node hash is the hash of both nodes
    hash_total = left.hash.to_s + right.hash.to_s
    @hash = Digest::SHA256.hexdigest(hash_total)
  end
end
