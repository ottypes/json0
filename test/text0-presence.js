const assert = require('assert');
const text = require('../lib/text0');

const { createPresence, comparePresence, transformPresence } = text;

// Inspired by ot-rich-text presence structure.
const sampleTextPresence = {
  u: '123',
  c: 8,
  s: [ [ 1, 1 ], [ 5, 7 ]]
};

// These tests are inspired by the ones found here:
// https://github.com/Teamwork/ot-rich-text/blob/master/test/Operation.js
describe('text0 presence', () => {
  describe('createPresence', () => {
    it('should return the passed in presence object', () => {
      assert.strictEqual(createPresence(sampleTextPresence), sampleTextPresence);
    });
  });

  describe('comparePresence', () => {
    it('should return true if equal', () => {
      assert(comparePresence(sampleTextPresence, sampleTextPresence));
    });

    it('should return false if not equal', () => {
      assert(!comparePresence(
        sampleTextPresence,
        Object.assign({}, sampleTextPresence, {
          s: [ [ 2, 2 ], [ 6, 8 ]]
        })
      ));
    });
  });

  describe('transformPresence', () => {
    it('should preserve original presence in case of no-op', () => {
      assert.deepEqual(
        transformPresence(sampleTextPresence, [], true),
        sampleTextPresence
      );
      assert.deepEqual(
        transformPresence(sampleTextPresence, [], false),
        sampleTextPresence
      );
    });

    it('should transform against string insertion', () => {
      assert.deepEqual(
        transformPresence(
          sampleTextPresence,
          [{ p: 0, i: 'a' }], // Insert the 'a' character at position 0.
          true
        ),
        Object.assign({}, sampleTextPresence, {
          s: [ [ 2, 2 ], [ 6, 8 ]]
        })
      );
    });

    it('should transform against own string insertion at presence position', () => {
      const isOwnOperation = true;
      assert.deepEqual(
        transformPresence( sampleTextPresence, [{ p: 1, i: 'a' }], isOwnOperation),
        Object.assign({}, sampleTextPresence, { s: [ [ 2, 2 ], [ 6, 8 ]] })
      );
    });

    it('should transform against non-own string insertion at presence position', () => {
      const isOwnOperation = false;
      assert.deepEqual(
        transformPresence( sampleTextPresence, [{ p: 1, i: 'a' }], isOwnOperation),
        Object.assign({}, sampleTextPresence, { s: [ [ 1, 1 ], [ 6, 8 ]] })
      );
    });

    it('should transform against string deletion', () => {
      assert.deepEqual(
        transformPresence(
          sampleTextPresence,
          [{ p: 0, d: 'a' }],
          true
        ),
        Object.assign({}, sampleTextPresence, {
          s: [ [ 0, 0 ], [ 4, 6 ]]
        })
      );
    });

    it('should transform against ops with multiple components deletion', () => {
      assert.deepEqual(
        transformPresence(
          sampleTextPresence,
          [
            { p: 0, i: 'a' },
            { p: 6, d: 'b' }
          ],
          true
        ),
        Object.assign({}, sampleTextPresence, {
          s: [ [ 2, 2 ], [ 6, 7 ]]
        })
      );
    });
  });
});
