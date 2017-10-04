# Reproduction for https://github.com/meteor/meteor/issues/8598

We've been investigating user reports that Meteor's oplog tailing operation can
stall.  I've tracked it down to a race condition in the Node Mongo driver.

There honestly might be more than one underlying bug, but this one appears to be
the culprit at least some of the time.

My understanding of the issue: It is possible for Pool's availableConnections
list to accidentally contain duplicates. This then leads to the socketCount() in
connectionFailureHandler to stay at 1 even after the last connection has been
removed, because of its duplicate. This means that the server and pool do not
got destroyed.

This has a couple of effects.

One of them is that, if messages end up in the 'queue' of the pool, they will
never trigger the NODE-1039 fix (which is itself buggy due to referencing a
nonexistent variable).

Another effect is that the `self.topology.isConnected` check in cursor.js's
`nextFunction` can return true even when we actually closed our last connection
to a server.  That means that the cursor fails to take advantage of the
disconnectHandler and instead tries to send the query immediately on the server
which is actually closed but whose state is somewhat corrupted.

In practice the latter seems to be the most directly applicable bug, because
fixing this issue means that the messages in question never end up on the Pool's
`queue` in the first place.

How does this availableConnections duplicate situation occur? Honestly there may
be multiple ways, as the list is manipulated in a bunch of places with no
duplicate checks.

The one I found is: if there is an in-flight replset `pingServer` ismaster
command when MongoClient calls Pool.prototype.auth, then its connection will be in
`inUseConnections` rather than `availableConnections`.
`authenticateLiveConnections` will **not** clear that list, and so when its
response comes back, `authenticateStragglers` will move the connection from
`inUseConnections` to `availableConnections`. Then when
`authenticateLiveConnections` has successfully authed the connection, its concat
will get the connection in there twice.

I have "hacked" pool.js to make this race condition more likely, by making
Pool.prototype.auth delay its main body until there `inUseConnections` is
non-empty. It only does this once per Pools and only for the first two Pools
created, to minimize the impact on the reproduction.  This delay is (when
running against localhost about 10 seconds, which may seem improbable, but this
definitely did correspond to real results I saw frequently when running against
Compose's MongoDB Classic 3.0.11.

# How to reproduce

Check out this git repo.  You can choose either the `broken` branch, which
contains the reproduction (including the hack that makes the race condition more
liekly), or the `fixed` branch (which also includes the bug fix).

First, run `./install.sh` to download a consistent version of `mongodb` and
`mongo` into the current directory.  You'll then need four shells.

## Shell 1: Mongod

Run `./run_mongod.sh` in one shell. It will run two copies of mongod, set up a
replset, add a root user, restart the mongods with auth, and wait for the
replsets to be ready again. Once it says `Ready to run the reproduction`, start
your second shell.

This script tries to manage the mongod processes and kill them on exit.  It uses
`./data` to store the databases, mongod logs, and other data, and it completely
wipes it out and starts over whenever you re-run the script.

## Shell 2: Insertion loop

Run `./loop.sh` in the second shell.  Every second, it will try to insert a
document into a collection against both servers. One should succeed and the
other should fail with a "not master" error. You can use this to tell which is
currently master.  Keep this window open: you can use it to see if step-downs
are actually taking effect.

## Shell 3: Node oplog tailer

Run `./run_node.sh` in the third shell. This runs a Node script using the Node
driver.  (I am running it with Node 8.5.0; it does use some ES6 features so you
need a reasonably recent Node. If this is a problem I can make it work on older
Nodes.)  Note that this is the only use of the Node driver in the reproduction:
everything else uses the `mongo` shell.

This script connects to the replset and tails the oplog.  The script itself is
in `pure-node/index.js`. It uses a copy of the mongodb driver that has been
checked into the git repo --- no need to run `npm install`.

You should see it connect to the servers. It will print "stalling" while it's
setting up the race condition and "done stalling" when it's done (**twice each,
for the two servers**).  Don't go on until you've see `done stalling` twice.
For some reason this seems to only sometimes work --- either you'll see two
`done stalling` messages close to each other, or you'll just see one and we
won't actually be able to reproduce the bug. So if you only see one `done
stalling`, try `run_node.sh` again. If you still can't get two `done stalling`
messages to occur, maybe try stepping down the primary (see step 4)?  This is
the only aspect of the reproduction that has been inconsistent; sorry.

Anyway, once you've got the `done stalling` bit taken care of, the script will
tail the oplog. It will (assuming you're running `loop.sh`) printing out a
`*******GOT DOC*********` message about every second. Because the inserted
document has a field that's a timestamp string, you can see which iterations of
`loop.sh` correspond to which oplog entries.

## Shell 4: Stepping down

Once you've got the other three processes going, run `./step_down.sh` in a
fourth shell. This will ask the current primary to step down.  You should see
your `loop.sh` start to successfully write to the other server, perhaps with a
few iterations in the middle where both are errors.

Note that this doesn't always actually make the step-down happen.: sometimes it
prints a message about `No electable secondaries caught up`. In that case, just
try again in a few seconds.

Confusingly, when this **succeeds**, it usually looks like an error: something
like `Error: error doing query: failed`. That's because a successful step-down
terminates the connection that sent the message.

OK, so you've had a successful step-down, according to `loop.sh`.  Look over at
your `run_node.sh` shell.

If you're on the `broken` git branch, the lovely stream of `*******GOT DOC*********`
will have ground to a halt.  It should print some messages about observing
primary changes, but the oplog tailing will not keep going.

If you're on the `fixed` git branch, the tailing should instead recover and
start showing `*******GOT DOC*********` very soon.
