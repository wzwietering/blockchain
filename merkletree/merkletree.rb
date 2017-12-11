require 'digest'
require_relative 'leaf'
require_relative 'node'

class MerkleTree
  attr_reader :root

  def initialize(transactions)
    @root = nil
    leafs = leafify(transactions)
    create_tree(leafs)
  end

  def create_tree(nodes)
    if nodes.length < 1
      raise ArgumentError.new("Nodes are required for a valid merkletree")
    elsif nodes.length == 1
      @root = nodes[0]
    else
      parents = []
      (0...nodes.length).step(2).each do |x|
        right = (x + 1 > nodes.length) ? nil : nodes[x + 1]
        parent = Node.new(nodes[x], right)
        parents.push(parent)
      end
      create_tree(parents)
    end
  end

  # Turn transactions into leafs
  def leafify(transactions)
    leafs = []
    transactions.each do |x|
      leafs.push(Leaf.new(x))
    end
    return leafs
  end
end
