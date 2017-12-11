require 'digest'

class Leaf
  attr_reader :transaction, :hash

  def initialize(transaction)
    @transaction = transaction
    @hash = Digest::SHA256.hexdigest(transaction.to_s)
  end
end
