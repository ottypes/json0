const assert = require('assert');
const json = require('../lib/json0');
const text = require('../lib/text0');
const otRichText = require('@teamwork/ot-rich-text')

const { createInsertText, createRetain, createDelete } = otRichText.Action

json.registerSubtype(otRichText.type);

const { createPresence, comparePresence, transformPresence } = json;

// Sample presence object using ot-rich-text sub-presence.
const samplePresence = {
  p: ['some', 'path'], // Path of the presence.
  t: 'ot-rich-text',   // Subtype of the presence (a registered subtype).
  s: {                 // Opaque presence object (subtype-specific structure).
    u: '123',          // An example of an ot-rich-text presence object.
    c: 8,
    s: [ [ 1, 1 ], [ 5, 7 ]]
  }
}

// Sample presence object using text0 sub-presence.
const sampleTextPresence = Object.assign({}, samplePresence, {
  t: 'text0'
});

// Sample presence object indicating only that
// the user has "joined" the document at the top level.
const samplePathOnlyPresence = { p: [] };

//// These tests are inspired by the ones found here:
//// https://github.com/Teamwork/ot-rich-text/blob/master/test/Operation.js
describe('json0 presence', () => {
  describe('createPresence', () => {
    it('should return the passed in presence object', () => {
      assert.strictEqual(createPresence(samplePresence), samplePresence);
    });
  });

  describe('comparePresence', () => {
    it('should return true if equal', () => {
      assert(comparePresence(samplePresence, samplePresence));
    });

    it('should return false if not equal', () => {
      assert(!comparePresence(samplePresence, sampleTextPresence));
    });
  });

  describe('transformPresence', () => {
    it('should preserve original presence in case of no-op', () => {
      assert.deepEqual(
        transformPresence(samplePresence, [], true),
        samplePresence
      );
      assert.deepEqual(
        transformPresence(samplePresence, [], false),
        samplePresence
      );
    });

    it('should transform by subtype op with matching path and subtype', () => {
      const o = [ createInsertText('a') ];
      const op = [{ p: ['some', 'path'], t: otRichText.type.name, o }];
      const isOwnOp = true;

      assert.deepEqual(
        transformPresence( samplePresence, op, isOwnOp),
        Object.assign({}, samplePresence, {
          s: otRichText.type.transformPresence(samplePresence.s, o, isOwnOp)
        })
      );
    });

    it('should transform by op with multiple components', () => {
      const o1 = [ createInsertText('foo') ];
      const o2 = [ createRetain(3), createDelete(2), createInsertText('a') ];

      let s = samplePresence.s;
      s = otRichText.type.transformPresence(s, o1);
      s = otRichText.type.transformPresence(s, o2);

      assert.deepEqual(
        transformPresence(samplePresence, [
          { p: ['some', 'path'], t: otRichText.type.name, o: o1 },
          { p: ['some', 'path'], t: otRichText.type.name, o: o2 }
        ]),
        Object.assign({}, samplePresence, { s })
      );
    });

    it('should not transform by op with matching path and non-matching subtype', () => {
      assert.deepEqual(
        transformPresence(samplePresence, [{
          p: ['some', 'path'],
          t: 'some-invalid-name',
          o: [ createInsertText('a') ]
        }]),
        samplePresence
      );
    });

    it('should not transform by op with non-matching path and matching subtype', () => {
      assert.deepEqual(
        transformPresence(samplePresence, [{
          p: ['some', 'other', 'path'],
          t: otRichText.type.name,
          o: [ createInsertText('a') ]
        }]),
        samplePresence
      );
    });

    it('should transform by text0 op', () => {
      const o = [{ p: 0, i: 'a' }];
      const op = [{ p: ['some', 'path'], t: text.name, o }]; // text0 op
      assert.deepEqual(
        transformPresence(sampleTextPresence, op),
        Object.assign({}, sampleTextPresence, {
          s: text.transformPresence(sampleTextPresence.s, o)
        })
      );
    });

    it('should transform by text op (auto-convert to & from internal text0 type)', () => {
      const o = [{ p: 0, i: 'a' }];
      const op = [{ p: ['some', 'path', 0], si: 'a' }]; // json0 text op
      const opClone = JSON.parse(JSON.stringify(op));

      assert.deepEqual(
        transformPresence(sampleTextPresence, op),
        Object.assign({}, sampleTextPresence, {
          s: text.transformPresence(sampleTextPresence.s, o)
        })
      );

      // Ensure the original op survives.
      assert.deepEqual(op, opClone);
    });

    it('should not break when given path-only presence', () => {
      assert.deepEqual(
        transformPresence(samplePathOnlyPresence, [{
          p: ['some', 'path', 0],
          si: 'a'
        }]),
        samplePathOnlyPresence
      );
    });
  });
});
