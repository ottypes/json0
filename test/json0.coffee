# Tests for JSON OT type.

assert = require 'assert'
nativetype = require '../lib/json0'

fuzzer = require 'ot-fuzzer'

# Cross-transform helper function. Transform server by client and client by
# server. Returns [server, client].
transformX = (type, left, right) ->
  [type.transform(left, right, 'left'), type.transform(right, left, 'right')]

genTests = (type) ->
  # The random op tester above will test that the OT functions are admissable,
  # but debugging problems it detects is a pain.
  #
  # These tests should pick up *most* problems with a normal JSON OT
  # implementation.

  describe 'sanity', ->
    describe '#create()', -> it 'returns null', ->
      assert.deepEqual type.create(), null

    describe '#compose()', ->
      it 'od,oi --> od+oi', ->
        assert.deepEqual [{p:['foo'], od:1, oi:2}], type.compose [{p:['foo'],od:1}],[{p:['foo'],oi:2}]
        assert.deepEqual [{p:['foo'], od:1},{p:['bar'], oi:2}], type.compose [{p:['foo'],od:1}],[{p:['bar'],oi:2}]
      it 'merges od+oi, od+oi -> od+oi', ->
        assert.deepEqual [{p:['foo'], od:1, oi:2}], type.compose [{p:['foo'],od:1,oi:3}],[{p:['foo'],od:3,oi:2}]


    describe '#transform()', -> it 'returns sane values', ->
      t = (op1, op2) ->
        assert.deepEqual op1, type.transform op1, op2, 'left'
        assert.deepEqual op1, type.transform op1, op2, 'right'

      t [], []
      t [{p:['foo'], oi:1}], []
      t [{p:['foo'], oi:1}], [{p:['bar'], oi:2}]

  describe 'number', ->
    it 'Adds a number', ->
      assert.deepEqual 3, type.apply 1, [{p:[], na:2}]
      assert.deepEqual [3], type.apply [1], [{p:[0], na:2}]

    it 'compresses two adds together in compose', ->
      assert.deepEqual [{p:['a', 'b'], na:3}], type.compose [{p:['a', 'b'], na:1}], [{p:['a', 'b'], na:2}]
      assert.deepEqual [{p:['a'], na:1}, {p:['b'], na:2}], type.compose [{p:['a'], na:1}], [{p:['b'], na:2}]

    it 'doesn\'t overwrite values when it merges na in append', ->
      rightHas = 21
      leftHas = 3

      rightOp = [{"p":[],"od":0,"oi":15},{"p":[],"na":4},{"p":[],"na":1},{"p":[],"na":1}]
      leftOp = [{"p":[],"na":4},{"p":[],"na":-1}]
      [right_, left_] = transformX type, rightOp, leftOp

      s_c = type.apply rightHas, left_
      c_s = type.apply leftHas, right_
      assert.deepEqual s_c, c_s


  # Strings should be handled internally by the text type. We'll just do some basic sanity checks here.
  describe 'string', ->
    describe '#apply()', -> it 'works', ->
      assert.deepEqual 'abc', type.apply 'a', [{p:[1], si:'bc'}]
      assert.deepEqual 'bc', type.apply 'abc', [{p:[0], sd:'a'}]
      assert.deepEqual {x:'abc'}, type.apply {x:'a'}, [{p:['x', 1], si:'bc'}]

    describe '#transform()', ->
      it 'splits deletes', ->
        assert.deepEqual type.transform([{p:[0], sd:'ab'}], [{p:[1], si:'x'}], 'left'), [{p:[0], sd:'a'}, {p:[1], sd:'b'}]

      it 'cancels out other deletes', ->
        assert.deepEqual type.transform([{p:['k', 5], sd:'a'}], [{p:['k', 5], sd:'a'}], 'left'), []

      it 'does not throw errors with blank inserts', ->
        assert.deepEqual type.transform([{p: ['k', 5], si:''}], [{p: ['k', 3], si: 'a'}], 'left'), []

  describe 'string subtype', ->
    describe '#apply()', ->
      it 'works', ->
        assert.deepEqual 'abc', type.apply 'a', [{p:[], t:'text0', o:[{p:1, i:'bc'}]}]
        assert.deepEqual 'bc', type.apply 'abc', [{p:[], t:'text0', o:[{p:0, d:'a'}]}]
        assert.deepEqual {x:'abc'}, type.apply {x:'a'}, [{p:['x'], t:'text0', o:[{p:1, i:'bc'}]}]

    describe '#transform()', ->
      it 'splits deletes', ->
        a = [{p:[], t:'text0', o:[{p:0, d:'ab'}]}]
        b = [{p:[], t:'text0', o:[{p:1, i:'x'}]}]
        assert.deepEqual type.transform(a, b, 'left'), [{p:[], t:'text0', o:[{p:0, d:'a'}, {p:1, d:'b'}]}]

      it 'cancels out other deletes', ->
        assert.deepEqual type.transform([{p:['k'], t:'text0', o:[{p:5, d:'a'}]}], [{p:['k'], t:'text0', o:[{p:5, d:'a'}]}], 'left'), []

      it 'does not throw errors with blank inserts', ->
        assert.deepEqual type.transform([{p:['k'], t:'text0', o:[{p:5, i:''}]}], [{p:['k'], t:'text0', o:[{p:3, i:'a'}]}], 'left'), []

  describe 'list', ->
    describe 'apply', ->
      it 'inserts', ->
        assert.deepEqual ['a', 'b', 'c'], type.apply ['b', 'c'], [{p:[0], li:'a'}]
        assert.deepEqual ['a', 'b', 'c'], type.apply ['a', 'c'], [{p:[1], li:'b'}]
        assert.deepEqual ['a', 'b', 'c'], type.apply ['a', 'b'], [{p:[2], li:'c'}]

      it 'deletes', ->
        assert.deepEqual ['b', 'c'], type.apply ['a', 'b', 'c'], [{p:[0], ld:'a'}]
        assert.deepEqual ['a', 'c'], type.apply ['a', 'b', 'c'], [{p:[1], ld:'b'}]
        assert.deepEqual ['a', 'b'], type.apply ['a', 'b', 'c'], [{p:[2], ld:'c'}]

      it 'replaces', ->
        assert.deepEqual ['a', 'y', 'b'], type.apply ['a', 'x', 'b'], [{p:[1], ld:'x', li:'y'}]

      it 'moves', ->
        assert.deepEqual ['a', 'b', 'c'], type.apply ['b', 'a', 'c'], [{p:[1], lm:0}]
        assert.deepEqual ['a', 'b', 'c'], type.apply ['b', 'a', 'c'], [{p:[0], lm:1}]

      ###
      'null moves compose to nops', ->
        assert.deepEqual [], type.compose [], [{p:[3],lm:3}]
        assert.deepEqual [], type.compose [], [{p:[0,3],lm:3}]
        assert.deepEqual [], type.compose [], [{p:['x','y',0],lm:0}]
      ###

    describe '#transform()', ->
      it 'bumps paths when list elements are inserted or removed', ->
        assert.deepEqual [{p:[2, 200], si:'hi'}], type.transform [{p:[1, 200], si:'hi'}], [{p:[0], li:'x'}], 'left'
        assert.deepEqual [{p:[1, 201], si:'hi'}], type.transform [{p:[0, 201], si:'hi'}], [{p:[0], li:'x'}], 'right'
        assert.deepEqual [{p:[0, 202], si:'hi'}], type.transform [{p:[0, 202], si:'hi'}], [{p:[1], li:'x'}], 'left'
        assert.deepEqual [{p:[2], t:'text0', o:[{p:200, i:'hi'}]}], type.transform [{p:[1], t:'text0', o:[{p:200, i:'hi'}]}], [{p:[0], li:'x'}], 'left'
        assert.deepEqual [{p:[1], t:'text0', o:[{p:201, i:'hi'}]}], type.transform [{p:[0], t:'text0', o:[{p:201, i:'hi'}]}], [{p:[0], li:'x'}], 'right'
        assert.deepEqual [{p:[0], t:'text0', o:[{p:202, i:'hi'}]}], type.transform [{p:[0], t:'text0', o:[{p:202, i:'hi'}]}], [{p:[1], li:'x'}], 'left'

        assert.deepEqual [{p:[0, 203], si:'hi'}], type.transform [{p:[1, 203], si:'hi'}], [{p:[0], ld:'x'}], 'left'
        assert.deepEqual [{p:[0, 204], si:'hi'}], type.transform [{p:[0, 204], si:'hi'}], [{p:[1], ld:'x'}], 'left'
        assert.deepEqual [{p:['x',3], si: 'hi'}], type.transform [{p:['x',3], si:'hi'}], [{p:['x',0,'x'], li:0}], 'left'
        assert.deepEqual [{p:['x',3,'x'], si: 'hi'}], type.transform [{p:['x',3,'x'], si:'hi'}], [{p:['x',5], li:0}], 'left'
        assert.deepEqual [{p:['x',4,'x'], si: 'hi'}], type.transform [{p:['x',3,'x'], si:'hi'}], [{p:['x',0], li:0}], 'left'
        assert.deepEqual [{p:[0], t:'text0', o:[{p:203, i:'hi'}]}], type.transform [{p:[1], t:'text0', o:[{p:203, i:'hi'}]}], [{p:[0], ld:'x'}], 'left'
        assert.deepEqual [{p:[0], t:'text0', o:[{p:204, i:'hi'}]}], type.transform [{p:[0], t:'text0', o:[{p:204, i:'hi'}]}], [{p:[1], ld:'x'}], 'left'
        assert.deepEqual [{p:['x'], t:'text0', o:[{p:3,i: 'hi'}]}], type.transform [{p:['x'], t:'text0', o:[{p:3, i:'hi'}]}], [{p:['x',0,'x'], li:0}], 'left'

        assert.deepEqual [{p:[1],ld:2}], type.transform [{p:[0],ld:2}], [{p:[0],li:1}], 'left'
        assert.deepEqual [{p:[1],ld:2}], type.transform [{p:[0],ld:2}], [{p:[0],li:1}], 'right'

      it 'converts ops on deleted elements to noops', ->
        assert.deepEqual [], type.transform [{p:[1, 0], si:'hi'}], [{p:[1], ld:'x'}], 'left'
        assert.deepEqual [], type.transform [{p:[1], t:'text0', o:[{p:0, i:'hi'}]}], [{p:[1], ld:'x'}], 'left'
        assert.deepEqual [{p:[0],li:'x'}], type.transform [{p:[0],li:'x'}], [{p:[0],ld:'y'}], 'left'
        assert.deepEqual [], type.transform [{p:[0],na:-3}], [{p:[0],ld:48}], 'left'

      it 'converts ops on replaced elements to noops', ->
        assert.deepEqual [], type.transform [{p:[1, 0], si:'hi'}], [{p:[1], ld:'x', li:'y'}], 'left'
        assert.deepEqual [], type.transform [{p:[1], t:'text0', o:[{p:0, i:'hi'}]}], [{p:[1], ld:'x', li:'y'}], 'left'
        assert.deepEqual [{p:[0], li:'hi'}], type.transform [{p:[0], li:'hi'}], [{p:[0], ld:'x', li:'y'}], 'left'

      it 'changes deleted data to reflect edits', ->
        assert.deepEqual [{p:[1], ld:'abc'}], type.transform [{p:[1], ld:'a'}], [{p:[1, 1], si:'bc'}], 'left'
        assert.deepEqual [{p:[1], ld:'abc'}], type.transform [{p:[1], ld:'a'}], [{p:[1], t:'text0', o:[{p:1, i:'bc'}]}], 'left'

      it 'Puts the left op first if two inserts are simultaneous', ->
        assert.deepEqual [{p:[1], li:'a'}], type.transform [{p:[1], li:'a'}], [{p:[1], li:'b'}], 'left'
        assert.deepEqual [{p:[2], li:'b'}], type.transform [{p:[1], li:'b'}], [{p:[1], li:'a'}], 'right'

      it 'converts an attempt to re-delete a list element into a no-op', ->
        assert.deepEqual [], type.transform [{p:[1], ld:'x'}], [{p:[1], ld:'x'}], 'left'
        assert.deepEqual [], type.transform [{p:[1], ld:'x'}], [{p:[1], ld:'x'}], 'right'


    describe '#compose()', ->
      it 'composes insert then delete into a no-op', ->
        assert.deepEqual [], type.compose [{p:[1], li:'abc'}], [{p:[1], ld:'abc'}]
        assert.deepEqual [{p:[1],ld:null,li:'x'}], type.transform [{p:[0],ld:null,li:"x"}], [{p:[0],li:"The"}], 'right'

      it 'doesn\'t change the original object', ->
        a = [{p:[0],ld:'abc',li:null}]
        assert.deepEqual [{p:[0],ld:'abc'}], type.compose a, [{p:[0],ld:null}]
        assert.deepEqual [{p:[0],ld:'abc',li:null}], a

      it 'composes together adjacent string ops', ->
        assert.deepEqual [{p:[100], si:'hi'}], type.compose [{p:[100], si:'h'}], [{p:[101], si:'i'}]
        assert.deepEqual [{p:[], t:'text0', o:[{p:100, i:'hi'}]}], type.compose [{p:[], t:'text0', o:[{p:100, i:'h'}]}], [{p:[], t:'text0', o:[{p:101, i:'i'}]}]

    it 'moves ops on a moved element with the element', ->
      assert.deepEqual [{p:[10], ld:'x'}], type.transform [{p:[4], ld:'x'}], [{p:[4], lm:10}], 'left'
      assert.deepEqual [{p:[10, 1], si:'a'}], type.transform [{p:[4, 1], si:'a'}], [{p:[4], lm:10}], 'left'
      assert.deepEqual [{p:[10], t:'text0', o:[{p:1, i:'a'}]}], type.transform [{p:[4], t:'text0', o:[{p:1, i:'a'}]}], [{p:[4], lm:10}], 'left'
      assert.deepEqual [{p:[10, 1], li:'a'}], type.transform [{p:[4, 1], li:'a'}], [{p:[4], lm:10}], 'left'
      assert.deepEqual [{p:[10, 1], ld:'b', li:'a'}], type.transform [{p:[4, 1], ld:'b', li:'a'}], [{p:[4], lm:10}], 'left'

      assert.deepEqual [{p:[0],li:null}], type.transform [{p:[0],li:null}], [{p:[0],lm:1}], 'left'
      # [_,_,_,_,5,6,7,_]
      # c: [_,_,_,_,5,'x',6,7,_]   p:5 li:'x'
      # s: [_,6,_,_,_,5,7,_]       p:5 lm:1
      # correct: [_,6,_,_,_,5,'x',7,_]
      assert.deepEqual [{p:[6],li:'x'}], type.transform [{p:[5],li:'x'}], [{p:[5],lm:1}], 'left'
      # [_,_,_,_,5,6,7,_]
      # c: [_,_,_,_,5,6,7,_]  p:5 ld:6
      # s: [_,6,_,_,_,5,7,_]  p:5 lm:1
      # correct: [_,_,_,_,5,7,_]
      assert.deepEqual [{p:[1],ld:6}], type.transform [{p:[5],ld:6}], [{p:[5],lm:1}], 'left'
      #assert.deepEqual [{p:[0],li:{}}], type.transform [{p:[0],li:{}}], [{p:[0],lm:0}], 'right'
      assert.deepEqual [{p:[0],li:[]}], type.transform [{p:[0],li:[]}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[2],li:'x'}], type.transform [{p:[2],li:'x'}], [{p:[0],lm:1}], 'left'

    it 'moves target index on ld/li', ->
      assert.deepEqual [{p:[0],lm:1}], type.transform [{p:[0], lm: 2}], [{p:[1], ld:'x'}], 'left'
      assert.deepEqual [{p:[1],lm:3}], type.transform [{p:[2], lm: 4}], [{p:[1], ld:'x'}], 'left'
      assert.deepEqual [{p:[0],lm:3}], type.transform [{p:[0], lm: 2}], [{p:[1], li:'x'}], 'left'
      assert.deepEqual [{p:[3],lm:5}], type.transform [{p:[2], lm: 4}], [{p:[1], li:'x'}], 'left'
      assert.deepEqual [{p:[1],lm:1}], type.transform [{p:[0], lm: 0}], [{p:[0], li:28}], 'left'

    it 'tiebreaks lm vs. ld/li', ->
      assert.deepEqual [], type.transform [{p:[0], lm: 2}], [{p:[0], ld:'x'}], 'left'
      assert.deepEqual [], type.transform [{p:[0], lm: 2}], [{p:[0], ld:'x'}], 'right'
      assert.deepEqual [{p:[1], lm:3}], type.transform [{p:[0], lm: 2}], [{p:[0], li:'x'}], 'left'
      assert.deepEqual [{p:[1], lm:3}], type.transform [{p:[0], lm: 2}], [{p:[0], li:'x'}], 'right'

    it 'replacement vs. deletion', ->
      assert.deepEqual [{p:[0],li:'y'}], type.transform [{p:[0],ld:'x',li:'y'}], [{p:[0],ld:'x'}], 'right'

    it 'replacement vs. insertion', ->
      assert.deepEqual [{p:[1],ld:{},li:"brillig"}], type.transform [{p:[0],ld:{},li:"brillig"}], [{p:[0],li:36}], 'left'

    it 'replacement vs. replacement', ->
      assert.deepEqual [], type.transform [{p:[0],ld:null,li:[]}], [{p:[0],ld:null,li:0}], 'right'
      assert.deepEqual [{p:[0],ld:[],li:0}], type.transform [{p:[0],ld:null,li:0}], [{p:[0],ld:null,li:[]}], 'left'

    it 'composes replace with delete of replaced element results in insert', ->
      assert.deepEqual [{p:[2],ld:[]}], type.compose [{p:[2],ld:[],li:null}], [{p:[2],ld:null}]

    it 'lm vs lm', ->
      assert.deepEqual [{p:[0],lm:2}], type.transform [{p:[0],lm:2}], [{p:[2],lm:1}], 'left'
      assert.deepEqual [{p:[4],lm:4}], type.transform [{p:[3],lm:3}], [{p:[5],lm:0}], 'left'
      assert.deepEqual [{p:[2],lm:0}], type.transform [{p:[2],lm:0}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[2],lm:1}], type.transform [{p:[2],lm:0}], [{p:[1],lm:0}], 'right'
      assert.deepEqual [{p:[3],lm:1}], type.transform [{p:[2],lm:0}], [{p:[5],lm:0}], 'right'
      assert.deepEqual [{p:[3],lm:0}], type.transform [{p:[2],lm:0}], [{p:[5],lm:0}], 'left'
      assert.deepEqual [{p:[0],lm:5}], type.transform [{p:[2],lm:5}], [{p:[2],lm:0}], 'left'
      assert.deepEqual [{p:[0],lm:5}], type.transform [{p:[2],lm:5}], [{p:[2],lm:0}], 'left'
      assert.deepEqual [{p:[0],lm:0}], type.transform [{p:[1],lm:0}], [{p:[0],lm:5}], 'right'
      assert.deepEqual [{p:[0],lm:0}], type.transform [{p:[1],lm:0}], [{p:[0],lm:1}], 'right'
      assert.deepEqual [{p:[1],lm:1}], type.transform [{p:[0],lm:1}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[1],lm:2}], type.transform [{p:[0],lm:1}], [{p:[5],lm:0}], 'right'
      assert.deepEqual [{p:[3],lm:2}], type.transform [{p:[2],lm:1}], [{p:[5],lm:0}], 'right'
      assert.deepEqual [{p:[2],lm:1}], type.transform [{p:[3],lm:1}], [{p:[1],lm:3}], 'left'
      assert.deepEqual [{p:[2],lm:3}], type.transform [{p:[1],lm:3}], [{p:[3],lm:1}], 'left'
      assert.deepEqual [{p:[2],lm:6}], type.transform [{p:[2],lm:6}], [{p:[0],lm:1}], 'left'
      assert.deepEqual [{p:[2],lm:6}], type.transform [{p:[2],lm:6}], [{p:[0],lm:1}], 'right'
      assert.deepEqual [{p:[2],lm:6}], type.transform [{p:[2],lm:6}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[2],lm:6}], type.transform [{p:[2],lm:6}], [{p:[1],lm:0}], 'right'
      assert.deepEqual [{p:[0],lm:2}], type.transform [{p:[0],lm:1}], [{p:[2],lm:1}], 'left'
      assert.deepEqual [{p:[2],lm:0}], type.transform [{p:[2],lm:1}], [{p:[0],lm:1}], 'right'
      assert.deepEqual [{p:[1],lm:1}], type.transform [{p:[0],lm:0}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[0],lm:0}], type.transform [{p:[0],lm:1}], [{p:[1],lm:3}], 'left'
      assert.deepEqual [{p:[3],lm:1}], type.transform [{p:[2],lm:1}], [{p:[3],lm:2}], 'left'
      assert.deepEqual [{p:[3],lm:3}], type.transform [{p:[3],lm:2}], [{p:[2],lm:1}], 'left'

    it 'changes indices correctly around a move', ->
      assert.deepEqual [{p:[1,0],li:{}}], type.transform [{p:[0,0],li:{}}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[0],lm:0}], type.transform [{p:[1],lm:0}], [{p:[0],ld:{}}], 'left'
      assert.deepEqual [{p:[0],lm:0}], type.transform [{p:[0],lm:1}], [{p:[1],ld:{}}], 'left'
      assert.deepEqual [{p:[5],lm:0}], type.transform [{p:[6],lm:0}], [{p:[2],ld:{}}], 'left'
      assert.deepEqual [{p:[1],lm:0}], type.transform [{p:[1],lm:0}], [{p:[2],ld:{}}], 'left'
      assert.deepEqual [{p:[1],lm:1}], type.transform [{p:[2],lm:1}], [{p:[1],ld:3}], 'right'

      assert.deepEqual [{p:[1],ld:{}}], type.transform [{p:[2],ld:{}}], [{p:[1],lm:2}], 'right'
      assert.deepEqual [{p:[2],ld:{}}], type.transform [{p:[1],ld:{}}], [{p:[2],lm:1}], 'left'


      assert.deepEqual [{p:[0],ld:{}}], type.transform [{p:[1],ld:{}}], [{p:[0],lm:1}], 'right'

      assert.deepEqual [{p:[0],ld:1,li:2}], type.transform [{p:[1],ld:1,li:2}], [{p:[1],lm:0}], 'left'
      assert.deepEqual [{p:[0],ld:2,li:3}], type.transform [{p:[1],ld:2,li:3}], [{p:[0],lm:1}], 'left'
      assert.deepEqual [{p:[1],ld:3,li:4}], type.transform [{p:[0],ld:3,li:4}], [{p:[1],lm:0}], 'left'

    it 'li vs lm', ->
      li = (p) -> [{p:[p],li:[]}]
      lm = (f,t) -> [{p:[f],lm:t}]
      xf = type.transform

      assert.deepEqual (li 0), xf (li 0), (lm 1, 3), 'left'
      assert.deepEqual (li 1), xf (li 1), (lm 1, 3), 'left'
      assert.deepEqual (li 1), xf (li 2), (lm 1, 3), 'left'
      assert.deepEqual (li 2), xf (li 3), (lm 1, 3), 'left'
      assert.deepEqual (li 4), xf (li 4), (lm 1, 3), 'left'

      assert.deepEqual (lm 2, 4), xf (lm 1, 3), (li 0), 'right'
      assert.deepEqual (lm 2, 4), xf (lm 1, 3), (li 1), 'right'
      assert.deepEqual (lm 1, 4), xf (lm 1, 3), (li 2), 'right'
      assert.deepEqual (lm 1, 4), xf (lm 1, 3), (li 3), 'right'
      assert.deepEqual (lm 1, 3), xf (lm 1, 3), (li 4), 'right'

      assert.deepEqual (li 0), xf (li 0), (lm 1, 2), 'left'
      assert.deepEqual (li 1), xf (li 1), (lm 1, 2), 'left'
      assert.deepEqual (li 1), xf (li 2), (lm 1, 2), 'left'
      assert.deepEqual (li 3), xf (li 3), (lm 1, 2), 'left'

      assert.deepEqual (li 0), xf (li 0), (lm 3, 1), 'left'
      assert.deepEqual (li 1), xf (li 1), (lm 3, 1), 'left'
      assert.deepEqual (li 3), xf (li 2), (lm 3, 1), 'left'
      assert.deepEqual (li 4), xf (li 3), (lm 3, 1), 'left'
      assert.deepEqual (li 4), xf (li 4), (lm 3, 1), 'left'

      assert.deepEqual (lm 4, 2), xf (lm 3, 1), (li 0), 'right'
      assert.deepEqual (lm 4, 2), xf (lm 3, 1), (li 1), 'right'
      assert.deepEqual (lm 4, 1), xf (lm 3, 1), (li 2), 'right'
      assert.deepEqual (lm 4, 1), xf (lm 3, 1), (li 3), 'right'
      assert.deepEqual (lm 3, 1), xf (lm 3, 1), (li 4), 'right'

      assert.deepEqual (li 0), xf (li 0), (lm 2, 1), 'left'
      assert.deepEqual (li 1), xf (li 1), (lm 2, 1), 'left'
      assert.deepEqual (li 3), xf (li 2), (lm 2, 1), 'left'
      assert.deepEqual (li 3), xf (li 3), (lm 2, 1), 'left'


  describe 'object', ->
    it 'passes sanity checks', ->
      assert.deepEqual {x:'a', y:'b'}, type.apply {x:'a'}, [{p:['y'], oi:'b'}]
      assert.deepEqual {}, type.apply {x:'a'}, [{p:['x'], od:'a'}]
      assert.deepEqual {x:'b'}, type.apply {x:'a'}, [{p:['x'], od:'a', oi:'b'}]

    it 'Ops on deleted elements become noops', ->
      assert.deepEqual [], type.transform [{p:[1, 0], si:'hi'}], [{p:[1], od:'x'}], 'left'
      assert.deepEqual [], type.transform [{p:[1], t:'text0', o:[{p:0, i:'hi'}]}], [{p:[1], od:'x'}], 'left'
      assert.deepEqual [], type.transform [{p:[9],si:"bite "}], [{p:[],od:"agimble s",oi:null}], 'right'
      assert.deepEqual [], type.transform [{p:[], t:'text0', o:[{p:9, i:"bite "}]}], [{p:[],od:"agimble s",oi:null}], 'right'

    it 'Ops on replaced elements become noops', ->
      assert.deepEqual [], type.transform [{p:[1, 0], si:'hi'}], [{p:[1], od:'x', oi:'y'}], 'left'
      assert.deepEqual [], type.transform [{p:[1], t:'text0', o:[{p:0, i:'hi'}]}], [{p:[1], od:'x', oi:'y'}], 'left'

    it 'Deleted data is changed to reflect edits', ->
      assert.deepEqual [{p:[1], od:'abc'}], type.transform [{p:[1], od:'a'}], [{p:[1, 1], si:'bc'}], 'left'
      assert.deepEqual [{p:[1], od:'abc'}], type.transform [{p:[1], od:'a'}], [{p:[1], t:'text0', o:[{p:1, i:'bc'}]}], 'left'
      assert.deepEqual [{p:[],od:25,oi:[]}], type.transform [{p:[],od:22,oi:[]}], [{p:[],na:3}], 'left'
      assert.deepEqual [{p:[],od:{toves:""},oi:4}], type.transform [{p:[],od:{toves:0},oi:4}], [{p:["toves"],od:0,oi:""}], 'left'
      assert.deepEqual [{p:[],od:"thou an",oi:[]}], type.transform [{p:[],od:"thou and ",oi:[]}], [{p:[7],sd:"d "}], 'left'
      assert.deepEqual [{p:[],od:"thou an",oi:[]}], type.transform [{p:[],od:"thou and ",oi:[]}], [{p:[], t:'text0', o:[{p:7, d:"d "}]}], 'left'
      assert.deepEqual [], type.transform([{p:["bird"],na:2}], [{p:[],od:{bird:38},oi:20}], 'right')
      assert.deepEqual [{p:[],od:{bird:40},oi:20}], type.transform([{p:[],od:{bird:38},oi:20}], [{p:["bird"],na:2}], 'left')
      assert.deepEqual [{p:['He'],od:[]}], type.transform [{p:["He"],od:[]}], [{p:["The"],na:-3}], 'right'
      assert.deepEqual [], type.transform [{p:["He"],oi:{}}], [{p:[],od:{},oi:"the"}], 'left'

    it 'If two inserts are simultaneous, the lefts insert will win', ->
      assert.deepEqual [{p:[1], oi:'a', od:'b'}], type.transform [{p:[1], oi:'a'}], [{p:[1], oi:'b'}], 'left'
      assert.deepEqual [], type.transform [{p:[1], oi:'b'}], [{p:[1], oi:'a'}], 'right'

    it 'parallel ops on different keys miss each other', ->
      assert.deepEqual [{p:['a'], oi: 'x'}], type.transform [{p:['a'], oi:'x'}], [{p:['b'], oi:'z'}], 'left'
      assert.deepEqual [{p:['a'], oi: 'x'}], type.transform [{p:['a'], oi:'x'}], [{p:['b'], od:'z'}], 'left'
      assert.deepEqual [{p:["in","he"],oi:{}}], type.transform [{p:["in","he"],oi:{}}], [{p:["and"],od:{}}], 'right'
      assert.deepEqual [{p:['x',0],si:"his "}], type.transform [{p:['x',0],si:"his "}], [{p:['y'],od:0,oi:1}], 'right'
      assert.deepEqual [{p:['x'], t:'text0', o:[{p:0, i:"his "}]}], type.transform [{p:['x'],t:'text0', o:[{p:0, i:"his "}]}], [{p:['y'],od:0,oi:1}], 'right'

    it 'replacement vs. deletion', ->
      assert.deepEqual [{p:[],oi:{}}], type.transform [{p:[],od:[''],oi:{}}], [{p:[],od:['']}], 'right'

    it 'replacement vs. replacement', ->
      assert.deepEqual [],                     type.transform [{p:[],od:['']},{p:[],oi:{}}], [{p:[],od:['']},{p:[],oi:null}], 'right'
      assert.deepEqual [{p:[],od:null,oi:{}}], type.transform [{p:[],od:['']},{p:[],oi:{}}], [{p:[],od:['']},{p:[],oi:null}], 'left'
      assert.deepEqual [],                     type.transform [{p:[],od:[''],oi:{}}], [{p:[],od:[''],oi:null}], 'right'
      assert.deepEqual [{p:[],od:null,oi:{}}], type.transform [{p:[],od:[''],oi:{}}], [{p:[],od:[''],oi:null}], 'left'

      # test diamond property
      rightOps = [ {"p":[],"od":null,"oi":{}} ]
      leftOps = [ {"p":[],"od":null,"oi":""} ]
      rightHas = type.apply(null, rightOps)
      leftHas = type.apply(null, leftOps)

      [left_, right_] = transformX type, leftOps, rightOps
      assert.deepEqual leftHas, type.apply rightHas, left_
      assert.deepEqual leftHas, type.apply leftHas, right_


    it 'An attempt to re-delete a key becomes a no-op', ->
      assert.deepEqual [], type.transform [{p:['k'], od:'x'}], [{p:['k'], od:'x'}], 'left'
      assert.deepEqual [], type.transform [{p:['k'], od:'x'}], [{p:['k'], od:'x'}], 'right'

  describe 'randomizer', ->
    @timeout 20000
    @slow 6000
    it 'passes', ->
      fuzzer type, require('./json0-generator'), 1000

    it 'passes with string subtype', ->
      type._testStringSubtype = true # hack
      fuzzer type, require('./json0-generator'), 1000
      delete type._testStringSubtype

describe 'json', ->
  describe 'native type', -> genTests nativetype
  #exports.webclient = genTests require('../helpers/webclient').types.json
