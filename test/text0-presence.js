const assert = require('assert');
const text = require('../lib/text0');

const { createPresence, transformPresence } = text;

// Inspired by ot-rich-text presence structure.
const samplePresence = {
  u: '123',
  c: 8,
  s: [ [ 1, 1 ], [ 5, 7 ]]
};

// These tests are inspired by the ones found here:
// https://github.com/Teamwork/ot-rich-text/blob/master/test/Operation.js
describe.only('text0 presence', () => {
  describe('createPresence', () => {
    it('should return the passed in presence object', () => {
      assert.strictEqual(createPresence(samplePresence), samplePresence);
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

    it('should transform against string insertion', () => {
      assert.deepEqual(
        transformPresence(
          samplePresence,
          [{ p: 0, i: 'a' }], // Insert the 'a' character at position 0.
          true
        ),
        Object.assign({}, samplePresence, {
          s: [ [ 2, 2 ], [ 6, 8 ]]
        })
      );
    });

    it('should transform against own string insertion at presence position', () => {
      const isOwnOperation = true;
      assert.deepEqual(
        transformPresence( samplePresence, [{ p: 1, i: 'a' }], isOwnOperation),
        Object.assign({}, samplePresence, { s: [ [ 2, 2 ], [ 6, 8 ]] })
      );
    });

    it('should transform against non-own string insertion at presence position', () => {
      const isOwnOperation = false;
      assert.deepEqual(
        transformPresence( samplePresence, [{ p: 1, i: 'a' }], isOwnOperation),
        Object.assign({}, samplePresence, { s: [ [ 1, 1 ], [ 6, 8 ]] })
      );
    });
  });
});
//  it('top level string operations', () => {
//    // Before selection
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [[5, 7]] },
//        [{ p: [0], si: 'a' }], // Insert the 'a' character at position 0.
//        true
//      ),
//      { u: 'user', c: 8, s: [[6, 8]] }
//    );
//
//    // Inside selection
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [[5, 7]] },
//        [{ p: [6], si: 'a' }],
//        true
//      ),
//      { u: 'user', c: 8, s: [[5, 8]] }
//    );
//
//    // Multiple characters
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [[5, 7]] },
//        [{ p: [6], si: 'abc' }],
//        true
//      ),
//      { u: 'user', c: 8, s: [[5, 10]] }
//    );
//
//    // String deletion
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [[5, 7]] },
//        [{ p: [5], sd: 'abc' }],
//        true
//      ),
//      { u: 'user', c: 8, s: [[5, 5]] }
//    );
//
//    // After selection
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [[5, 7]] },
//        [{ p: [8], si: 'a' }],
//        true
//      ),
//      { u: 'user', c: 8, s: [[5, 7]] }
//    );
//  });
//
//  it('nested string operations', () => {
//    // Single level
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [['content', 5, 7]] },
//        [{ p: ['content', 0], si: 'a' }], // Insert the 'a' character at position 0.
//        true
//      ),
//      { u: 'user', c: 8, s: [['content', 6, 8]] }
//    );
//
//    // Multiple level
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [['content', 'deeply', 'nested', 5, 7]] },
//        [{ p: ['content', 'deeply', 'nested', 0], si: 'a' }], // Insert the 'a' character at position 0.
//        true
//      ),
//      { u: 'user', c: 8, s: [['content', 'deeply', 'nested', 6, 8]] }
//    );
//
//    // Op not matching path
//    assert.deepEqual(
//      transformPresence(
//        { u: 'user', c: 8, s: [['content', 'deeply', 'nested', 5, 7]] },
//        [{ p: ['content', 'somewhere', 'else', 0], si: 'a' }], // Insert the 'a' character at position 0.
//        true
//      ),
//      { u: 'user', c: 8, s: [['content', 'deeply', 'nested', 5, 7]] }
//    );
//
//    // Multiple selections
//    assert.deepEqual(
//      transformPresence(
//        {
//          u: 'user',
//          c: 8,
//          s: [
//            ['content', 'deeply', 'nested', 5, 7],
//            ['content', 'somewhere', 'else', 5, 7]
//          ]
//        },
//        [{ p: ['content', 'somewhere', 'else', 0], si: 'a' }], // Insert the 'a' character at position 0.
//        true
//      ),
//      {
//        u: 'user',
//        c: 8,
//        s: [
//          ['content', 'deeply', 'nested', 5, 7],
//          ['content', 'somewhere', 'else', 6, 8]
//        ]
//      }
//    );
//  });
//
  //  TODO get to this point

  //assert.deepEqual(
  //  transformPresence(
  //    {u: 'user', c: 8, s: [[5, 7]]},
  //    [createRetain(3), createDelete(2), createInsertText('a')],
  //    true,
  //  ),
  //  {
  //    u: 'user',
  //    c: 8,
  //    s: [[4, 6]],
  //  },
  //);
  //assert.deepEqual(
  //  transformPresence(
  //    {
  //      u: 'user',
  //      c: 8,
  //      s: [[5, 7]],
  //    },
  //    [createRetain(3), createDelete(2), createInsertText('a')],
  //    false,
  //  ),
  //  {
  //    u: 'user',
  //    c: 8,
  //    s: [[3, 6]],
  //  },
  //);

  //assert.deepEqual(
  //  transformPresence(
  //    {
  //      u: 'user',
  //      c: 8,
  //      s: [[5, 7]],
  //    },
  //    [createRetain(5), createDelete(2), createInsertText('a')],
  //    true,
  //  ),
  //  {
  //    u: 'user',
  //    c: 8,
  //    s: [[6, 6]],
  //  },
  //);
  //assert.deepEqual(
  //  transformPresence(
  //    {
  //      u: 'user',
  //      c: 8,
  //      s: [[5, 7]],
  //    },
  //    [createRetain(5), createDelete(2), createInsertText('a')],
  //    false,
  //  ),
  //  {
  //    u: 'user',
  //    c: 8,
  //    s: [[5, 5]],
  //  },
  //);

  //assert.deepEqual(
  //  transformPresence(
  //    {
  //      u: 'user',
  //      c: 8,
  //      s: [[5, 7], [8, 2]],
  //    },
  //    [createInsertText('a')],
  //    false,
  //  ),
  //  {
  //    u: 'user',
  //    c: 8,
  //    s: [[6, 8], [9, 3]],
  //  },
  //);

  //assert.deepEqual(
  //  transformPresence(
  //    {
  //      u: 'user',
  //      c: 8,
  //      s: [[1, 1], [2, 2]],
  //    },
  //    [createInsertText('a')],
  //    false,
  //  ),
  //  {
  //    u: 'user',
  //    c: 8,
  //    s: [[2, 2], [3, 3]],
  //  },
  //);
//});
//
// describe('comparePresence', () => {
//   it('basic tests', () => {
//     assert.strictEqual(comparePresence(), true);
//     assert.strictEqual(comparePresence(undefined, undefined), true);
//     assert.strictEqual(comparePresence(null, null), true);
//     assert.strictEqual(comparePresence(null, undefined), false);
//     assert.strictEqual(comparePresence(undefined, null), false);
//     assert.strictEqual(
//       comparePresence(undefined, { u: '', c: 0, s: [] }),
//       false
//     );
//     assert.strictEqual(comparePresence(null, { u: '', c: 0, s: [] }), false);
//     assert.strictEqual(
//       comparePresence({ u: '', c: 0, s: [] }, undefined),
//       false
//     );
//     assert.strictEqual(comparePresence({ u: '', c: 0, s: [] }, null), false);
//
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]] },
//         { u: 'user', c: 8, s: [[1, 2]] }
//       ),
//       true
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2], [4, 6]] },
//         { u: 'user', c: 8, s: [[1, 2], [4, 6]] }
//       ),
//       true
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]], unknownProperty: 5 },
//         { u: 'user', c: 8, s: [[1, 2]] }
//       ),
//       true
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]] },
//         { u: 'user', c: 8, s: [[1, 2]], unknownProperty: 5 }
//       ),
//       true
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]] },
//         { u: 'userX', c: 8, s: [[1, 2]] }
//       ),
//       false
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]] },
//         { u: 'user', c: 9, s: [[1, 2]] }
//       ),
//       false
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]] },
//         { u: 'user', c: 8, s: [[3, 2]] }
//       ),
//       false
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[1, 2]] },
//         { u: 'user', c: 8, s: [[1, 3]] }
//       ),
//       false
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[9, 8], [1, 2]] },
//         { u: 'user', c: 8, s: [[9, 8], [3, 2]] }
//       ),
//       false
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[9, 8], [1, 2]] },
//         { u: 'user', c: 8, s: [[9, 8], [1, 3]] }
//       ),
//       false
//     );
//     assert.strictEqual(
//       comparePresence(
//         { u: 'user', c: 8, s: [[9, 8], [1, 2]] },
//         { u: 'user', c: 8, s: [[9, 8]] }
//       ),
//       false
//     );
//   });
// });
//
// describe('isValidPresence', () => {
//   it('basic tests', () => {
//     assert.strictEqual(isValidPresence(), false);
//     assert.strictEqual(isValidPresence(null), false);
//     assert.strictEqual(isValidPresence([]), false);
//     assert.strictEqual(isValidPresence({}), false);
//     assert.strictEqual(isValidPresence({ u: 5, c: 8, s: [] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: '8', s: [] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: 8.5, s: [] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: Infinity, s: [] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: NaN, s: [] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: 8, s: {} }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: 8, s: [] }), true);
//     assert.strictEqual(isValidPresence({ u: '5', c: 8, s: [[]] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: 8, s: [[1]] }), false);
//     assert.strictEqual(isValidPresence({ u: '5', c: 8, s: [[1, 2]] }), true);
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2, 3]] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], []] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, 6]] }),
//       true
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, '6']] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, 6.1]] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, Infinity]] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, NaN]] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, -0]] }),
//       true
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], [3, -1]] }),
//       true
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, 2], ['3', 0]] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [[1, '2'], [4, 0]] }),
//       false
//     );
//     assert.strictEqual(
//       isValidPresence({ u: '5', c: 8, s: [['1', 2], [4, 0]] }),
//       false
//     );
//   });
// });
