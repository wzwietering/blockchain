require 'sinatra'
require 'securerandom'
require 'json'

require_relative 'datastructures/blockchain'

blockchain = Blockchain.new
node_identifier = SecureRandom.uuid

get '/mine' do
  blockchain.new_transaction(0, node_identifier, 1)

  block = blockchain.new_block

  response = {
    :message => "New Block Forged",
    :index => block[:index],
    :transactions => block[:transactions],
    :proof => block[:proof],
    :previous_hash => block[:previous_hash],
    :merkle_root => block[:merkle_root]
  }

  content_type :json
  status 201
  response.to_json
end

# Transaction routes
post '/transactions/new' do
  values = JSON.parse(request.body.read)
  required = ['sender', 'recipient', 'amount']
  if not required.all? {|s| values.key? s}
    status 400
    body "Missing values: " + (required - values.keys).join(",")
    return
  end

  index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
  response = {:message => "Transaction will be added to block #{index}"}

  content_type :json
  status 201
  response.to_json
end

get '/transactions/current' do
  response = {
    :transactions => blockchain.current_transactions
  }
  status 200
  content_type :json
  response.to_json
end

# Chain routes
get '/chain' do
  chain = blockchain.chain
  response = {
    :chain => chain,
    :length => chain.length
  }

  content_type :json
  status 200
  response.to_json
end

get '/chain/valid' do
  valid = blockchain.valid_chain?(blockchain.chain)
  response = {
    :message => valid
  }
  content_type :json
  status 200
  response.to_json
end

post '/chain/index' do
  values = JSON.parse(request.body.read, :symbolize_names => true)
  required = [:index]
  if not required.all? {|s| values.key? s}
    status 400
    body "Missing values: " + (required - values.keys).join(",")
    return
  end
  if values[:index] > blockchain.chain.length
    status 404
    return body "Index is higher than chain length"
  end
  response = blockchain.chain[values[:index]]
  content_type :json
  status 200
  response.to_json
end

post '/chain/range' do
  values = JSON.parse(request.body.read, :symbolize_names => true)
  required = [:from]
  if not required.all? {|s| values.key? s}
    status 400
    body "Missing values: " + (required - values.keys).join(",")
    return
  end

  if values[:from] > blockchain.chain.length
    status 400
    return body "From is higher than chain length"
  end

  if values.key?(:to)
    if values[:to] > blockchain.chain.length
      status 400
      return body "To is higher than chain length"
    else
      response = blockchain.chain[values[:from]..values[:to]]
    end
  else
    response = blockchain.chain.slice(values[:from], blockchain.chain.length - values[:from])
  end
  content_type :json
  status 200
  response.to_json
end

# Node routes
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
  if blockchain.load?
    response = {
      :message => 'Blockchain loaded'
    }
    content_type :json
    status 200
    response.to_json
  else 
    response = {
      :message => 'No blockchain found'
    }
    content_type :json
    status 404
    response.to_json
  end
end

post '/block/valid' do
  values = JSON.parse(request.body.read, :symbolize_names => true)
  required = [:index, :timestamp, :transactions, :previous_hash, :merkle_root, :proof]
  if not required.all? {|s| values.key? s}
    status 400
    body "Missing values: " + (required - values.keys).join(",")
    return
  end
  valid = blockchain.class.valid_block?(values)
  response = {
    :message => valid
  }
  content_type :json
  status 200
  response.to_json
end
