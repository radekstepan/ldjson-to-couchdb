{ assert }  = require 'chai'
{ resolve } = require 'path'
ndjson      = require 'ndjson'
_           = require 'highland'
proxy       = do require('proxyquire').noCallThru
{ EOL }     = require 'os'

nano = {}

through = proxy resolve(__dirname, '../README.coffee.md'), nano: -> nano

pipeline = (docs, args, cb) ->
  _.pipeline.apply _, [
    _(docs)
    do ndjson.serialize
    through.apply null, args
    do _.collect
    _.apply cb
  ]

module.exports =
  'bulk docs insert': (done) ->
    docs = [ { 'val': '1' }, { 'val': '2' } ]
    args = [ 'http://' ]
    
    called = 0

    nano.bulk = (data, cb) ->
      called += 1
      cb null, data.docs

    pipeline docs, args, (res) ->
      _(docs).map(JSON.stringify).toArray (data) ->
        assert.deepEqual res, ( line + EOL for line in data )
        assert.equal called, 1
        do done

  'doc insert (no key on doc)': (done) ->
    docs = [ { 'val': '1' }, { 'val': '2' } ]
    args = [ 'http://', 'doesnotexist' ]

    called = 0

    nano.insert = (data, cb) ->
      called += 1
      cb null, data

    pipeline docs, args, (res) ->
      _(docs).map(JSON.stringify).toArray (data) ->
        assert.deepEqual res, ( line + EOL for line in data )
        assert.equal called, 2
        do done

  'doc update': (done) ->
    docs = [
      { '_id': 'number', 'val': 'one' }
      { '_id': 'number', 'val': 'two' }
      { '_id': 'number', 'val': 'three' }
    ]
    args = [ 'http://', '_id' ]

    db = {}

    nano.head = (doc_name, cb) ->
      headers = null
      headers = { 'etag': "'#{doc._rev}'" } if doc = db[doc_name]
      cb null, null, headers

    nano.insert = (doc, doc_name, cb) ->
      doc._rev ?= '-1'
      # Bump the version.
      doc._rev = String 1 + parseInt doc._rev, 10
      db[doc_name] = doc
      cb null, doc

    pipeline docs, args, (res) ->
      resp = [
        { '_id': 'number', 'val': 'one', '_rev': '0' }
        { '_id': 'number', 'val': 'two', '_rev': '1' }
        { '_id': 'number', 'val': 'three', '_rev': '2' }
      ]

      # Each res document is an encoded string in an array.
      _(resp).map(JSON.stringify).toArray (data) ->
        assert.deepEqual res, ( line + EOL for line in data )
        do done