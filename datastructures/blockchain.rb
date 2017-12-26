require 'digest'
require 'json'
require 'net/http'
require 'set'
require 'uri'

require_relative 'merkletree'

class Blockchain
  attr_reader :chain, :nodes, :current_transactions

  def initialize
    @chain = []
    @current_transactions = []
    @nodes = Set.new

    chain.push(genesis_block)
  end

  def genesis_block
    transactions = [{:sender => 0, :recipient => 0, :amount => 0}]
    merkle_root = MerkleTree.new(transactions).root.hash
    block = {
      :index => 0,
      :timestamp => 0,
      :transactions => transactions,
      :previous_hash => '0',
      :merkle_root => merkle_root
    }
    proof = proof_of_work(block)
    block[:proof] = proof
    return block
  end

  def register_node(address)
    uri = URI.parse(address)
    @nodes.add(uri.to_s)
  end

  def valid_chain?(chain)
    last_block = chain[0]
    current_index = 1

    while current_index < chain.length
      block = chain[current_index]

      # Validate relations and chronological order
      if block[:previous_hash] != self.class.hash(last_block)
        puts "Invalid hash of previous block on block #{block[:index]}"
        return false
      elsif block[:timestamp] < last_block[:timestamp]
        puts "Invalid block order based on time on block #{block[:index]}"
        return false
      elsif block[:index] < last_block[:index]
        puts "Invalid block order based on index on block #{block[:index]}"
        return false
      end

      # Validate block
      if not self.class.valid_block?(block)
        return false
      end

      last_block = block
      current_index += 1
    end

    return true
  end

  def self.valid_block?(block)
    if not self.valid_proof?(block, block[:proof])
      puts "Invalid proof on block #{block[:index]}"
      return false
    elsif not MerkleTree.valid_hash?(block[:merkle_root], block[:transactions])
      puts "Invalid merkleroot on block #{block[:index]}"
      return false
    else
      return true
    end
  end

  def resolve_conflicts?
    neighbours = @nodes
    new_chain = nil

    # Only look for long chains
    max_length = @chain.length

    # Grab and verify the chains from all the nodes in our network
    for node in neighbours
      uri = URI.parse("http://#{node}/chain")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if response.code == 200
        json = JSON.parse(response.body)
        length = json["length"]
        chain = json["chain"]

        # Check if the length is longer and the chain is valid
        if length > max_length and valid_chain?(chain)
          max_length = length
          new_chain = chain
        end
      end
    end

    # Replace our chain if we discovered a new, valid chain longer than ours
    if new_chain
      @chain = new_chain
      return true
    end

    return false
  end

  def new_block(previous_hash=nil)
    start = Time.now
    merkle_tree = MerkleTree.new(@current_transactions)
    merkle_root = merkle_tree.root.hash
    block = {
      :index => @chain.length,
      :timestamp => Time.now.utc.to_i,
      :transactions => @current_transactions,
      :previous_hash => (previous_hash or self.class.hash(last_block)),
      :merkle_root => merkle_root
    }

    proof = proof_of_work(block)
    block[:proof] = proof

    # Reset the current list of transactions
    @current_transactions = []

    @chain.push(block)
    save
    puts 'Block created in: ' + (Time.now - start).to_s + ' seconds'
    return block
  end

  def new_transaction(sender, recipient, amount)
    @current_transactions.push({
      :sender => sender,
      :recipient => recipient,
      :amount => amount,
    })

    save_transactions

    return last_block[:index] + 1
  end

  def self.hash(block)
    block_string = JSON.dump(block).encode('utf-8')
    return Digest::SHA256.hexdigest(block_string)
  end

  def proof_of_work(block)
    proof = 0
    start = Time.now
    while self.class.valid_proof?(block, proof) == false
      proof += 1
    end
    puts 'Proof found in: ' + (Time.now - start).to_s

    return proof
  end

  def self.valid_proof?(block, proof)
    block[:proof] = proof
    guess_hash = hash(block)
    return guess_hash[0...4] == "0000"
  end

  def last_block
    return @chain[-1]
  end

  def save
    json = @chain.to_json
    FileUtils.mkdir_p("data") unless Dir.exists?("data")
    File.open("data/blockchain.json","w") do |f|
      f.write(json)
    end
  end

  def save_transactions
    FileUtils.mkdir_p("data") unless Dir.exists?("data")
    File.open("data/pending_transactions.json","w") do |f|
      f.write(@current_transactions.to_json)
    end
  end

  # Returns if the load is succesful
  def load?
    if not File.exists?("data/blockchain.json")
      return false
    elsif not File.exists?("data/pending_transactions.json")
      return false
    else
      file = File.read "data/blockchain.json"
      @chain = JSON.parse(file, :symbolize_names => true)
      file = File.read "data/pending_transactions.json"
      @current_transactions = JSON.parse(file, :symbolize_names => true)
      return true
    end
  end
end
