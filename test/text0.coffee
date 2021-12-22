# Tests for the embedded non-composable text type text0.

assert = require 'assert'
fuzzer = require 'ot-fuzzer'
text0 = require '../lib/text0'

describe 'text0', ->
  describe 'compose', ->
    # Compose is actually pretty easy
    it 'is sane', ->
      assert.deepEqual text0.compose([], []), []
      assert.deepEqual text0.compose([{i:'x', p:0}], []), [{i:'x', p:0}]
      assert.deepEqual text0.compose([], [{i:'x', p:0}]), [{i:'x', p:0}]
      assert.deepEqual text0.compose([{i:'y', p:100}], [{i:'x', p:0}]), [{i:'y', p:100}, {i:'x', p:0}]

  describe 'transform', ->
    it 'is sane', ->
      assert.deepEqual [], text0.transform [], [], 'left'
      assert.deepEqual [], text0.transform [], [], 'right'

      assert.deepEqual [{i:'y', p:100}, {i:'x', p:0}], text0.transform [{i:'y', p:100}, {i:'x', p:0}], [], 'left'
      assert.deepEqual [], text0.transform [], [{i:'y', p:100}, {i:'x', p:0}], 'right'

    it 'inserts', ->
      assert.deepEqual [[{i:'x', p:10}], [{i:'a', p:1}]], text0.transformX [{i:'x', p:9}], [{i:'a', p:1}]
      assert.deepEqual [[{i:'x', p:10}], [{i:'a', p:11}]], text0.transformX [{i:'x', p:10}], [{i:'a', p:10}]

      assert.deepEqual [[{i:'x', p:10}], [{d:'a', p:9}]], text0.transformX [{i:'x', p:11}], [{d:'a', p:9}]
      assert.deepEqual [[{i:'x', p:10}], [{d:'a', p:10}]], text0.transformX [{i:'x', p:11}], [{d:'a', p:10}]
      assert.deepEqual [[{i:'x', p:11}], [{d:'a', p:12}]], text0.transformX [{i:'x', p:11}], [{d:'a', p:11}]

      assert.deepEqual [{i:'x', p:10}], text0.transform [{i:'x', p:10}], [{d:'a', p:11}], 'left'
      assert.deepEqual [{i:'x', p:10}], text0.transform [{i:'x', p:10}], [{d:'a', p:10}], 'left'
      assert.deepEqual [{i:'x', p:10}], text0.transform [{i:'x', p:10}], [{d:'a', p:10}], 'right'

    it 'deletes', ->
      assert.deepEqual [[{d:'abc', p:8}], [{d:'xy', p:4}]], text0.transformX [{d:'abc', p:10}], [{d:'xy', p:4}]
      assert.deepEqual [[{d:'ac', p:10}], []], text0.transformX [{d:'abc', p:10}], [{d:'b', p:11}]
      assert.deepEqual [[], [{d:'ac', p:10}]], text0.transformX [{d:'b', p:11}], [{d:'abc', p:10}]
      assert.deepEqual [[{d:'a', p:10}], []], text0.transformX [{d:'abc', p:10}], [{d:'bc', p:11}]
      assert.deepEqual [[{d:'c', p:10}], []], text0.transformX [{d:'abc', p:10}], [{d:'ab', p:10}]
      assert.deepEqual [[{d:'a', p:10}], [{d:'d', p:10}]], text0.transformX [{d:'abc', p:10}], [{d:'bcd', p:11}]
      assert.deepEqual [[{d:'d', p:10}], [{d:'a', p:10}]], text0.transformX [{d:'bcd', p:11}], [{d:'abc', p:10}]
      assert.deepEqual [[{d:'abc', p:10}], [{d:'xy', p:10}]], text0.transformX [{d:'abc', p:10}], [{d:'xy', p:13}]

  describe 'transformCursor', ->
    it 'is sane', ->
      assert.strictEqual 0, text0.transformCursor 0, [], 'right'
      assert.strictEqual 0, text0.transformCursor 0, [], 'left'
      assert.strictEqual 100, text0.transformCursor 100, []

    it 'works vs insert', ->
      assert.strictEqual 0, text0.transformCursor 0, [{i:'asdf', p:100}], 'right'
      assert.strictEqual 0, text0.transformCursor 0, [{i:'asdf', p:100}], 'left'

      assert.strictEqual 204, text0.transformCursor 200, [{i:'asdf', p:100}], 'right'
      assert.strictEqual 204, text0.transformCursor 200, [{i:'asdf', p:100}], 'left'

      assert.strictEqual 104, text0.transformCursor 100, [{i:'asdf', p:100}], 'right'
      assert.strictEqual 100, text0.transformCursor 100, [{i:'asdf', p:100}], 'left'

    it 'works vs delete', ->
      assert.strictEqual 0, text0.transformCursor 0, [{d:'asdf', p:100}], 'right'
      assert.strictEqual 0, text0.transformCursor 0, [{d:'asdf', p:100}], 'left'
      assert.strictEqual 0, text0.transformCursor 0, [{d:'asdf', p:100}]

      assert.strictEqual 196, text0.transformCursor 200, [{d:'asdf', p:100}]

      assert.strictEqual 100, text0.transformCursor 100, [{d:'asdf', p:100}]
      assert.strictEqual 100, text0.transformCursor 102, [{d:'asdf', p:100}]
      assert.strictEqual 100, text0.transformCursor 104, [{d:'asdf', p:100}]
      assert.strictEqual 101, text0.transformCursor 105, [{d:'asdf', p:100}]

  describe 'normalize', ->
    it 'is sane', ->
      testUnchanged = (op) -> assert.deepEqual op, text0.normalize op
      testUnchanged []
      testUnchanged [{i:'asdf', p:100}]
      testUnchanged [{i:'asdf', p:100}, {d:'fdsa', p:123}]

    it 'adds missing p:0', ->
      assert.deepEqual [{i:'abc', p:0}], text0.normalize [{i:'abc'}]
      assert.deepEqual [{d:'abc', p:0}], text0.normalize [{d:'abc'}]
      assert.deepEqual [{i:'abc', p:0}, {d:'abc', p:0}], text0.normalize [{i:'abc'}, {d:'abc'}]

    it 'converts op to an array', ->
      assert.deepEqual [{i:'abc', p:0}], text0.normalize {i:'abc', p:0}
      assert.deepEqual [{d:'abc', p:0}], text0.normalize {d:'abc', p:0}

    it 'works with a really simple op', ->
      assert.deepEqual [{i:'abc', p:0}], text0.normalize {i:'abc'}

    it 'compress inserts', ->
      assert.deepEqual [{i:'xyzabc', p:10}], text0.normalize [{i:'abc', p:10}, {i:'xyz', p:10}]
      assert.deepEqual [{i:'axyzbc', p:10}], text0.normalize [{i:'abc', p:10}, {i:'xyz', p:11}]
      assert.deepEqual [{i:'abcxyz', p:10}], text0.normalize [{i:'abc', p:10}, {i:'xyz', p:13}]

    it 'doesnt compress separate inserts', ->
      t = (op) -> assert.deepEqual op, text0.normalize op

      t [{i:'abc', p:10}, {i:'xyz', p:9}]
      t [{i:'abc', p:10}, {i:'xyz', p:14}]

    it 'compress deletes', ->
      assert.deepEqual [{d:'xyabc', p:8}], text0.normalize [{d:'abc', p:10}, {d:'xy', p:8}]
      assert.deepEqual [{d:'xabcy', p:9}], text0.normalize [{d:'abc', p:10}, {d:'xy', p:9}]
      assert.deepEqual [{d:'abcxy', p:10}], text0.normalize [{d:'abc', p:10}, {d:'xy', p:10}]

    it 'doesnt compress separate deletes', ->
      t = (op) -> assert.deepEqual op, text0.normalize op

      t [{d:'abc', p:10}, {d:'xyz', p:6}]
      t [{d:'abc', p:10}, {d:'xyz', p:11}]

  describe '#transformPresence', ->
    it 'transforms a zero-length range by an op before it', ->
      assert.deepEqual {index: 13, length: 0}, text0.transformPresence {index: 10, length: 0}, [{p: 0, i: 'foo'}]

    it 'does not transform a zero-length range by an op after it', ->
      assert.deepEqual {index: 10, length: 0}, text0.transformPresence {index: 10, length: 0}, [{p: 20, i: 'foo'}]

    it 'transforms a range with length by an op before it', ->
      assert.deepEqual {index: 13, length: 3}, text0.transformPresence {index: 10, length: 3}, [{p: 0, i: 'foo'}]

    it 'transforms a range with length by an op that deletes part of it', ->
      assert.deepEqual {index: 9, length: 1}, text0.transformPresence {index: 10, length: 3}, [{p: 9, d: 'abc'}]

    it 'transforms a range with length by an op that deletes the whole range', ->
      assert.deepEqual {index: 9, length: 0}, text0.transformPresence {index: 10, length: 3}, [{p: 9, d: 'abcde'}]

    it 'keeps extra metadata when transforming', ->
      assert.deepEqual {index: 13, length: 0, meta: 'lorem ipsum'}, text0.transformPresence {index: 10, length: 0, meta: 'lorem ipsum'}, [{p: 0, i: 'foo'}]

    it 'returns null when no presence is provided', ->
      assert.deepEqual null, text0.transformPresence undefined, [{p: 0, i: 'foo'}]

    it 'advances the cursor if inserting at own index', ->
      assert.deepEqual {index: 13, length: 2}, text0.transformPresence {index: 10, length: 2}, [{p: 10, i: 'foo'}], true

    it 'does not advance the cursor if not own op', ->
      assert.deepEqual {index: 10, length: 5}, text0.transformPresence {index: 10, length: 2}, [{p: 10, i: 'foo'}], false

    it 'does nothing if no op is provided', ->
      assert.deepEqual {index: 10, length: 0}, text0.transformPresence {index: 10, length: 0}, undefined

    it 'does not mutate the original range', ->
      range = {index: 10, length: 0}
      text0.transformPresence range, [{p: 0, i: 'foo'}]
      assert.deepEqual {index: 10, length: 0}, range


  describe 'randomizer', -> it 'passes', ->
    @timeout 4000
    @slow 4000
    fuzzer text0, require('./text0-generator')

