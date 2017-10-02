import { Meteor } from 'meteor/meteor';
import { Mongo } from 'meteor/mongo';

const c = new Mongo.Collection('c');
console.log("Cleaning up collection");
c.remove({});
console.log("Observing");
const o = c.find().observeChanges({
  added(id, fields) {
    console.log("add", id, fields);
  },
  changed(id, fields) {
    console.log("cha", id, fields);
  },
  removed(id) {
    console.log("rem", id);
  }
});
