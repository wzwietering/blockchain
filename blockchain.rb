require 'digest'
require 'json'
require 'net/http'
require 'set'
require 'uri'

class Blockchain
  attr_reader :chain, :nodes

  def initialize
    @chain = []
    @current_transactions = []
    @nodes = Set.new

    self.new_block(100, 1)
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
      puts "#{last_block}"
      puts "#{block}"
      puts "\n-----------\n"

      if block[:previous_hash] != self.class.hash(last_block)
        return false
      end
      if not self.class.valid_proof?(last_block[:proof], block[:proof])
        return false
      end

      last_block = block
      current_index += 1
    end

    return true
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

  def new_block(proof, previous_hash=nil)
    block = {
      :index => @chain.length + 1,
      :timestamp => Time.now.utc.to_i,
      :transactions => @current_transactions,
      :proof => proof,
      :previous_hash => (previous_hash or self.class.hash(@chain[-1])),
    }

    # Reset the current list of transactions
    @current_transactions = []

    @chain.push(block)
    save
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

  def proof_of_work(last_proof)
    proof = 0
    while self.class.valid_proof?(last_proof, proof) == false
      proof += 1
    end

    return proof
  end

  def self.valid_proof?(last_proof, proof)
    guess = "#{last_proof}#{proof}".encode('utf-8')
    guess_hash = Digest::SHA256.hexdigest(guess)
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

  def load
    file = File.read "data/blockchain.json"
    @chain = JSON.parse(file, :symbolize_names => true)
    file = File.read "data/pending_transactions.json"
    @current_transactions = JSON.parse(file, :symbolize_names => true)
  end
end
