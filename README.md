# Blockchain
This project contains a simple blockchain with an API and support for multiple nodes.

## Setup
Install ruby and the bundler gem. Run `bundle`.

## Usage
Enter `ruby app.rb` in your favorite terminal to start the server.
The application can be accessed via localhost:4567.
The server can do the following requests:
* `GET /mine` mines the current block
* `GET /chain` returns the full chain in JSON
* `GET /chain/valid` tells you whether the current chain is valid
* `GET /load` loads the previous used blockchain
* `GET /transactions/current` show the transactions which are not yet placed in a block
* `POST /transactions/new` to create a new transaction. The format is:
```json
{
  "sender": "your hash",
  "recipient": "the other hash",
  "amount": 123
}
```

For multiple nodes you can use the following requests:
* `GET /nodes/resolve` to resolve conflicts
* `POST /nodes/register` to add a list of new nodes using the following format:
```json
{
  "nodes": ["An ip adress or website"]
}
```

## Sources
[Bitcoin paper](https://bitcoin.org/bitcoin.pdf)
