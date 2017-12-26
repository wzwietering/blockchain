require 'digest'

class Leaf
  attr_reader :transaction, :hash

  # Add the transation to the leaf and hash it
  def initialize(transaction)
    @transaction = transaction
    @hash = Digest::SHA256.hexdigest(transaction.to_s)
  end
end
