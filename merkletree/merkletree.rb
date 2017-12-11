require 'digest'
require_relative 'leaf'
require_relative 'node'

class MerkleTree
  attr_reader :root 

  def initialize(transactions)
    leafs = self.class.leafify(transactions)
    @root = self.class.create_tree(leafs)
  end

  def self.create_tree(nodes)
    if nodes.length < 1
      raise ArgumentError.new("Nodes are required for a valid merkletree")
    elsif nodes.length == 1
      return nodes[0]
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
  def self.leafify(transactions)
    leafs = []
    transactions.each do |x|
      leafs.push(Leaf.new(x))
    end
    return leafs
  end

  # Check a hash by recalculating it
  def self.valid_hash?(hash, transactions)
    leafs = self.leafify(transactions)
    root = self.create_tree(leafs)
    return root.hash == hash
  end
end
