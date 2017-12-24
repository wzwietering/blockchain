require 'digest'

class Node
  attr_reader :left, :right, :hash

  def initialize(left, right=nil)
    @left = left
    @right = (right or left)
    hash_total = left.hash.to_s + right.hash.to_s
    @hash = Digest::SHA256.hexdigest(hash_total)
  end
end
