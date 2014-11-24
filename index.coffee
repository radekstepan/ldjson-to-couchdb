ndjson = require 'ndjson'
couch  = require 'nano'
_      = require 'highland'
nano   = require 'nano'

# Batch insert upto this many documents.
BATCH = 50

# Will throw err in bulk insert if uri not present/malformed.
db = nano process.argv[2]
# The document key on which to perform update.
key = process.argv[3]

through = (docs) ->
  # Bulk insert.
  return _ db.bulk { docs } unless key?

  update = (doc) ->
    # Just insert if our doc does not have a key.
    return _ db.insert doc unless (doc_name = doc[key])?

    _ (push, next) ->
      db.head doc_name, (err, res, { etag }) ->
        doc._rev = etag[1...-1]
        db.insert doc, doc_name, (err) ->
        push err, JSON.stringify doc
        push null, _.nil

  # Update pipeline.
  _.pipeline _(docs), _.map(update), _.parallel BATCH

# Split on newlines and pipe to a transform.
module.exports = _.pipeline.apply _, [
  do _
  do ndjson.parse
  _.batch BATCH
  _.map through
  do _.series
]