{ assert }  = require 'chai'
{ resolve } = require 'path'
ndjson      = require 'ndjson'
_           = require 'highland'
proxy       = do require('proxyquire').noCallThru

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
  'bulk insert': (done) ->
    docs = [ { 'val': '1' }, { 'val': '2' } ]
    args = [ 'http://' ]
    
    called = no

    nano.bulk = (data) ->
      called = yes
      data.docs

    pipeline docs, args, (res) ->
      assert.deepEqual res, docs
      assert called
      do done

  'single insert (no key on doc)': (done) ->
    docs = [ { 'val': '1' }, { 'val': '2' } ]
    args = [ 'http://', 'doesnotexist' ]

    called = 0

    nano.insert = (data) ->
      called += 1
      data

    pipeline docs, args, (res) ->
      assert.deepEqual res, docs
      assert.equal called, 2
      do done