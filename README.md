# Blockchain
This project contains a simple blockchain with an API

## Setup
Install ruby and the bundler gem. Run `bundle`.

## Usage
Enter `ruby app.rb` in your favorite terminal to start the server.
The application can be accessed via localhost:4567.
The server can do the following requests:
* `GET /mine` mines the current block
* `GET /chain` returns the full chain in JSON
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
* `POST /nodes/register` to create a new node using the following format:
```json
{
  "nodes": ["An ip adress or website"]
}
```
