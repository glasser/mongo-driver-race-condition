const MongoClient = require('mongodb').MongoClient;

MongoClient.connect(process.env.MONGO_OPLOG_URL, {
//  reconnectTries: Infinity,
  poolSize: 1,
}, (err, db) => {
  if (err) {
    throw err;
  }

  let primary;

  if (db.serverConfig.isMasterDoc) {
    primary = db.serverConfig.isMasterDoc.primary;
    console.log(`got initial primary: ${primary}`);
  }

  db.serverConfig.on('joined', (kind, doc) => {
    console.log(`got joined ${kind} ${primary} => ${JSON.stringify(doc)}`);
    if (kind === 'primary') {
      if (doc.primary !== primary) {
        primary = doc.primary;
        console.log(`failing over to ${primary}`);
      }
    } else if (doc.me === primary) {
      primary = null;
      console.log("no longer sure who is primary");
    }
  });

  db.collection('oplog.rs', (err, collection) => {
    if (err) {
      throw err;
    }

    const selector = {ns: /^testdb\./};

    // Find the last entry.
    collection.findOne(selector, {sort: {$natural: -1}, fields: {ts: 1}}, (err, last) => {
      if (err) {
        throw err;
      }

      if (last) {
        selector.ts = {$gt: last.ts};
      }

      const startTailing = () => {
        const cursor = collection.find(selector, {}, {
          tailable: true,
          awaitdata: true,
          numberOfRetries: -1,
        });

        const getNext = () => {
          console.log("calling nextObject");
          cursor.nextObject((err, doc) => {
            if (err) {
              console.log(`got error from nextObject: ${err}`);
              doc = null;
            }
            if (doc) {
              console.log("*******GOT DOC*********", doc);
              // If we restart the cursor later, start after this one.
              if (doc.ts) {
                selector.ts = {$gt: doc.ts};
              }
              setImmediate(getNext);
              return;
            }
            console.log("restarting cursor soon");
            setTimeout(startTailing, 100);
          });
        };

        setImmediate(getNext);
      };

      setImmediate(startTailing);
    });
  });
});
