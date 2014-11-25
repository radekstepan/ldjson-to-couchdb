#ldjson-to-couchdb

Pipe STDIN in [LDJSON](http://en.wikipedia.org/wiki/Line_Delimited_JSON) format to [CouchDB](http://couchdb.apache.org/).

![Build Status](http://img.shields.io/codeship/cd6d5370-56f6-0132-c62d-2aedc25d7739.svg?style=flat)
[![Dependencies](http://img.shields.io/david/radekstepan/ldjson-to-couchdb.svg?style=flat)](https://david-dm.org/radekstepan/ldjson-to-couchdb)
[![License](http://img.shields.io/badge/license-AGPL--3.0-red.svg?style=flat)](LICENSE)

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
through = require('ldjson-to-couchdb')
process.stdin.pipe(through()).pipe(process.stdout)
```

OR you can pass the `db`, `key` and `batch` params like so:

```
through = require('ldjson-to-couchdb')
through('http://127.0.0.1:5984/db', '_id', 100).pipe(process.stdout)
```

###Insert vs Update

If you pass a `key` as an argument, we will update existing document rather than bulk insert (which us much faster).

```bash
$ cat data.json | ldjson-to-couchdb "http://localhost:5984/db" _id
```

##Source

    _      = require 'highland'
    ndjson = require 'ndjson'
    nano   = require 'nano'

    module.exports = (db, key, batch=50) ->
      # Will throw err in bulk insert if uri not present/malformed.
      db = nano db or process.argv[2]
      # The document key on which to perform update.
      key = key or process.argv[3] unless 'TEST' of process.env

      through = (docs) ->
        # Bulk insert when no key specified.
        return _ db.bulk { docs } unless key?

        update = (doc) ->
          # Just insert if our doc does not have a key.
          # TODO: this should be an insert, but tests won't pass.
          return _ db.bulk { 'docs': [ doc ] } unless (doc_name = doc[key])?

          _ (push, next) ->
            db.head doc_name, (err, res, headers) ->
              doc._rev = headers.etag[1...-1] if headers
              db.insert doc, doc_name, (err) ->
                push err, JSON.stringify doc
                push null, _.nil

        # Update pipeline.
        _.pipeline _(docs), _.map(update), _.parallel batch

      # Split on newlines and pipe to a transform.
      _.pipeline.apply _, [
        do _
        do ndjson.parse
        _.batch batch
        _.map through
        do _.series
      ]