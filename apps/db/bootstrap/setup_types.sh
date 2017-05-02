# Create Bucket Types
RIAK_HOME=${RIAK_HOME:="/Users/randy/Documents/dev/views/riak_ts"}
RIAK_BIN_DIR=${RIAK_BIN_DIR:="rel/riak/bin"}
CMD=$RIAK_HOME/$RIAK_BIN_DIR/riak-admin
echo "Using Riak at: $RIAK_HOME/$RIAK_BIN_DIR"
$CMD bucket-type create hll $(cat hll-clean.json) && $CMD bucket-type activate hll
$CMD bucket-type create counter $(cat counter-clean.json) && $CMD bucket-type activate counter
$CMD bucket-type create set $(cat set-clean.json) && $CMD bucket-type activate set
$CMD bucket-type create map $(cat map-clean.json) && $CMD bucket-type activate map

# Load Static Data
