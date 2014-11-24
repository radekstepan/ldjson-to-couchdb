#ldjson-to-couchdb

Pipe STDIN in [LDJSON](http://en.wikipedia.org/wiki/Line_Delimited_JSON) format to [CouchDB](http://couchdb.apache.org/).

##Run

Install with [npm](https://www.npmjs.org/) and pipe `data.json` to CouchDB database called `db` on `localhost:5984`.

```bash
$ npm install ldjson-to-couchdb -g
$ cat data.json | ldjson-to-couchdb "http://localhost:5984/db"
```

It is your [job](http://docs.couchdb.org/en/latest/intro/api.html#databases) to make sure that `db` exists:

```bash
$ curl -X PUT http://127.0.0.1:5984/db
```

If using the module programmatically, you can pipe the output from CouchDB as follows:

```coffee-script
var through = require('ldjson-to-couchdb')
process.stdin.pipe(through).pipe(process.stdout)
```

###Insert vs Update

If you pass a `key` as an argument, we will update existing document rather than bulk insert (which us much faster).

```bash
$ cat data.json | ldjson-to-couchdb "http://localhost:5984/db" _id
```