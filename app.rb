require 'sinatra'
require 'securerandom'
require 'json'

require_relative 'blockchain'

blockchain = Blockchain.new
node_identifier = SecureRandom.uuid

get '/mine' do
  # Get the next proof
  last_block = blockchain.last_block
  last_proof = last_block[:proof]
  proof = blockchain.proof_of_work(last_proof)

  blockchain.new_transaction(0, node_identifier, 1)

  block = blockchain.new_block(proof)

  response = {
    :message => "New Block Forged",
    :index => block[:index],
    :transactions => block[:transactions],
    :proof => block[:proof],
    :previous_hash => block[:previous_hash],
  }

  content_type :json
  response.to_json
end

post '/transactions/new' do
  values = JSON.parse(request.body.read)
  required = ['sender', 'recipient', 'amount']
  if not required.all? {|s| values.key? s}
    status 400
    body "Missing values: " + (required - values.keys).join(",")
    return
  end

  index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
  response = {:message => "Transaction will be added to Block #{index}"}

  content_type :json
  response.to_json
end

get '/chain' do
  chain = blockchain.chain
  response = {
    :chain => chain,
    :length => chain.length
  }

  content_type :json
  response.to_json
end

post '/nodes/register' do
  values = JSON.parse(request.body.read)
  nodes = values["nodes"]

  if nodes.empty?
    status 400
    body "Error: Please supply a valid list of nodes"
    return
  end

  for node in nodes
    blockchain.register_node(node)
  end

  response = {
    :message => 'New nodes have been added',
    :total_nodes => blockchain.nodes.to_a
  }

  content_type :json
  status 201
  response.to_json
end

get '/nodes/resolve' do
  replaced = blockchain.resolve_conflicts?

  if replaced
    response = {
      :message => 'Our chain was replaced',
      :new_chain => blockchain.chain
    }
  else
    response = {
      :message => 'Our chain is authoritative',
      :chain => blockchain.chain
    }
  end

  content_type :json
  status 200
  response.to_json
end

get '/load' do
  if not File.exists?("data/blockchain.json")
    status 404
    response = {
      :message => 'blockchain.json does not exist'
    }
    return response.to_json
  elsif not File.exists?("data/pending_transactions.json")
    status 404
    response = {
      :message => 'pending_transactions.json does not exist'
    }
    return response.to_json
  else
    blockchain.load
    response = {
      :message => 'Blockchain loaded'
    }
    content_type :json
    status 200
    response.to_json
  end
end
