# JSON0 OT Type

The JSON OT type can be used to edit arbitrary JSON documents.

Forked from [ottypes/json0](https://github.com/ottypes/json0) to implement [presence](https://github.com/ottypes/docs/issues/29).

Current status: Presence is basically working, but it's only transformed by subtype ops. Remaining work includes transforming presence by ops that are not text (`si`, `sd`) or subtype ops. Includes `li`, `ld`, `lm`, `oi`, `od`. The goal is that one day this fork will be merged into ottypes/json0 via this PR: [ottypes/json0: Presence](https://github.com/ottypes/json0/pull/31).

In the mean time, this fork is published on NPM as [@datavis-tech/ot-json0](https://www.npmjs.com/package/@datavis-tech/ot-json0). If you want to try it out:

```
npm install -S @datavis-tech/ot-json0
```

To [use it as the default ShareDB OT Type](https://github.com/share/sharedb/issues/284), you'll need to do the following (in both client and server):

```js
const json0 = require('fork-of-ot-json0');
const ShareDB = require('sharedb'); // or require('sharedb/lib/client');
ShareDB.types.register(json0.type);
ShareDB.types.defaultType = json0.type;
```

To use the presence feature, you'll need to use the [Teamwork fork of ShareDB](https://github.com/teamwork/sharedb#readme) until the [ShareDB Presence PR](https://github.com/share/sharedb/pull/207) is merged.

## Features

The JSON OT type supports the following operations:

- Insert/delete/move/replace items in a list, shuffling adjacent list items as needed
- Object insert/delete/replace
- Atomic numerical add operation
- Embed arbitrary subtypes
- Embedded string editing, using the old text0 OT type as a subtype

JSON0 is an *invertable* type - which is to say, all operations have an inverse
operation which will undo the original op. As such, all operations which delete
content have the content to be deleted inline in the operation.

But its not perfect - here's a list of things it *cannot* do:

- Object-move
- Set if null (object insert with first writer wins semantics)
- Efficient list insert-of-many-items

It also has O(a * b) complexity when transforming large operations by one
another (as opposed to O(a + b) which better algorithms can manage).


## Operations

JSON operations are lists of operation components. The operation is a grouping
of these components, applied in order.

Each operation component is an object with a `p:PATH` component. The path is a
list of keys to reach the target element in the document. For example, given
the following document:

```
{'a':[100, 200, 300], 'b': 'hi'}
```

An operation to delete the first array element (`100`) would be the following:

```
[{p:['a', 0], ld:100}]
```

The path (`['a', 0]`) describes how to reach the target element from the root.
The first element is a key in the containing object and the second is an index
into the array.

### Summary of operations

 op                                    | Description
---------------------------------------|-------------------------------------
`{p:[path], na:x}`                     | adds `x` to the number at `[path]`.
`{p:[path,idx], li:obj}`               | inserts the object `obj` before the item at `idx` in the list at `[path]`.
`{p:[path,idx], ld:obj}`               | deletes the object `obj` from the index `idx` in the list at `[path]`.
`{p:[path,idx], ld:before, li:after}`  | replaces the object `before` at the index `idx` in the list at `[path]` with the object `after`.
`{p:[path,idx1], lm:idx2}`             | moves the object at `idx1` such that the object will be at index `idx2` in the list at `[path]`.
`{p:[path,key], oi:obj}`               | inserts the object `obj` into the object at `[path]` with key `key`.
`{p:[path,key], od:obj}`               | deletes the object `obj` with key `key` from the object at `[path]`.
`{p:[path,key], od:before, oi:after}`  | replaces the object `before` with the object `after` at key `key` in the object at `[path]`.
`{p:[path], t:subtype, o:subtypeOp}`   | applies the subtype op `o` of type `t` to the object at `[path]`
`{p:[path,offset], si:s}`              | inserts the string `s` at offset `offset` into the string at `[path]` (uses subtypes internally).
`{p:[path,offset], sd:s}`              | deletes the string `s` at offset `offset` from the string at `[path]` (uses subtypes internally).

---

### Number operations

The only operation you can perform on a number is to add to it. Remember, you
can always replace the number with another number by operating on the number's
container.

> Are there any other ways the format should support modifying numbers? Ideas:
>
> - Linear multiple as well (Ie, `x = Bx + C`)
> - MAX, MIN, etc? That would let you do timestamps...
>
> I can't think of any good use cases for those operations...

#### Add

Usage:

    {p:PATH, na:X}

Adds X to the number at PATH. If you want to subtract, add a negative number.

---

### Lists and Objects

Lists and objects have the same set of operations (*Insert*, *Delete*,
*Replace*, *Move*) but their semantics are very different. List operations
shuffle adjacent list items left or right to make space (or to remove space).
Object operations do not. You should pick the data structure which will give
you the behaviour you want when you design your data model. 

To make it clear what the semantics of operations will be, list operations and
object operations are named differently. (`li`, `ld`, `lm` for lists and `oi`,
`od` and `om` for objects).

#### Inserting, Deleting and Replacing in a list

Usage:

- **Insert**: `{p:PATH, li:NEWVALUE}`
- **Delete**: `{p:PATH, ld:OLDVALUE}`
- **Replace**: `{p:PATH, ld:OLDVALUE, li:NEWVALUE}`

Inserts, deletes, or replaces the element at `PATH`.

The last element in the path specifies an index in the list where elements will
be deleted, inserted or replaced. The index must be valid (0 <= *new index* <=
*list length*). The indexes of existing list elements may change when new
list elements are added or removed.

The replace operation:

    {p:PATH, ld:OLDVALUE, li:NEWVALUE}

is equivalent to a delete followed by an insert:

    {p:PATH, ld:OLDVALUE}
    {p:PATH, li:NEWVALUE}

Given the following list:

    [100, 300, 400]

applying the following operation:

    [{p:[1], li:{'yo':'hi there'}}, {p:[3], ld:400}]

would result in the following new list:

    [100, {'yo':'hi there'}, 300]


#### Moving list elements

You can move list items by deleting them and & inserting them back elsewhere,
but if you do that concurrent operations on the deleted element will be lost.
To fix this, the JSON OT type has a special list move operation.

Usage:

    {p:PATH, lm:NEWINDEX}

Moves the list element specified by `PATH` to a different place in the list,
with index `NEWINDEX`. Any elements between the old index and the new index
will get new indicies, as appropriate.

The new index must be 0 <= _index_ < _list length_. The new index will be
interpreted __after__ the element has been removed from its current position.
Given the following data:

    ['a', 'b', 'c']

the following operation:

    [{p:[1], lm:2}]

will result in the following data:

    ['a', 'c', 'b']


#### Inserting, Deleting and Replacing in an object

Usage:

- **Insert**: `{p:PATH, oi:NEWVALUE}`
- **Delete**: `{p:PATH, od:OLDVALUE}`
- **Replace**: `{p:PATH, od:OLDVALUE, oi:NEWVALUE}`

Set the element indicated by `PATH` from `OLDVALUE` to `NEWVALUE`. The last
element of the path must be the key of the element to be inserted, deleted or
replaced.

When inserting, the key must not already be used. When deleting or replacing a
value, `OLDVALUE` must be equal to the current value the object has at the
specified key.

As with lists, the replace operation:

    {p:PATH, od:OLDVALUE, oi:NEWVALUE}

is equivalent to a delete followed by an insert:

    {p:PATH, od:OLDVALUE}
    {p:PATH, oi:NEWVALUE}

There is (unfortunately) no equivalent for list move with objects.


---

### Subtype operations

Usage:
  
    {p:PATH, t:SUBTYPE, o:OPERATION}
    
`PATH` is the path to the object that will be modified by the subtype.
`SUBTYPE` is the name of the subtype, e.g. `"text0"`.
`OPERATION` is the subtype operation itself.

To register a subtype, call `json0.registerSubtype` with another OT type.
Specifically, a subtype is a JavaScript object with the following methods:

* `apply`
* `transform`
* `compose`
* `invert`

See the [OT types documentation](https://github.com/ottypes/docs) for details on these methods.

#### Text subtype

The old string operations are still supported (see below) but are now implemented internally as a subtype
using the `text0` type. You can either continue to use the original `si` and `sd` ops documented below,
or use the `text0` type as a subtype yourself.

To edit a string, create a `text0` subtype op. For example, given the
following object:

    {'key':[100,'abcde']}

If you wanted to delete the `'d'` from the string `'abcde'`, you would use the following operation:

    [{p:['key',1], t: 'text0', o:[{p:3, d:'d'}]}

Note the path. The components, in order, are the key to the list, and the index to
the `'abcde'` string. The offset to the `'d'` character in the string is given in
the subtype operation.

##### Insert into a string

Usage:

    {p:PATH, t:'text0', o:[{p:OFFSET, i:TEXT}]}
    
Insert `TEXT` to the string specified by `PATH` at the position specified by `OFFSET`.

##### Delete from a string

Usage:

    {p:PATH, t:'text0', o:[{p:OFFSET, d:TEXT}]}
    
Delete `TEXT` in the string specified by `PATH` at the position specified by `OFFSET`.

---

### String operations

These operations are now internally implemented as subtype operations using the `text0` type, but you can still use them if you like. See above.

If the content at a path is a string, an operation can edit the string
in-place, either deleting characters or inserting characters.

To edit a string, add the string offset to the path. For example, given the
following object:

    {'key':[100,'abcde']}

If you wanted to delete the `'d'` from the string `'abcde'`, you would use the following operation:

    [{p:['key',1,3],sd:'d'}]

Note the path. The components, in order, are the key to the list, the index to
the `'abcde'` string, and then the offset to the `'d'` character in the string.

#### Insert into a string

Usage:

    {p:PATH, si:TEXT}

Insert `TEXT` at the location specified by `PATH`. The path must specify an
offset in a string.

#### Delete from a string

Usage:

    {p:PATH, sd:TEXT}

Delete `TEXT` at the location specified by `PATH`. The path must specify an
offset in a string. `TEXT` must be contained at the location specified.

---

## Presence

(inspired by https://github.com/Teamwork/ot-rich-text#presence)

The shape of our presence data is as follows:

```js
{
  p: ['some', 'path'], // Path of the presence.
  t: 'ot-rich-text',   // Subtype of the presence (a registered subtype).
  s: {                 // Opaque presence object (subtype-specific structure).
    u: '123',          // An example of an ot-rich-text presence object.
    c: 8,
    s: [ [ 1, 1 ], [ 5, 7 ]]
  }
}
```

Here's a demo https://github.com/datavis-tech/json0-presence-demo

![presence](https://user-images.githubusercontent.com/68416/56134824-ffac3400-5fac-11e9-89a1-c60064c3eb67.gif)

![selections](https://user-images.githubusercontent.com/68416/56134832-033fbb00-5fad-11e9-9274-a19b2287c5b1.gif)


# Commentary

This library was written a couple of years ago by [Jeremy Apthorp](https://github.com/nornagon). It was
originally written in coffeescript as part of ShareJS, and then it got pulled
out into the share/ottypes library and its finally landed here.

The type uses the list-of-op-components model, where each operation makes a
series of individual changes to a document. Joseph now thinks this is a
terrible idea because it doesn't scale well to large operations - it has
N<sup>2</sup> instead of 2N complexity.

Jeremy and Joseph have talked about rewriting this library to instead make each
operation be a sparse traversal of the document. But it was obnoxiously
difficult to implement JSON OT correctly in the first place - it'll probably
take both of us thinking about nothing else for a few weeks to make that
happen.

When it was written, the embedded text0 type was sharejs's text type. Its since
been rewritten to make each operation be a traversal, but the JSON OT type
still embeds the old type. As such, that old text type is included in this
repository. If you want to use text0 in your own project, I'd be very happy to
pull it out of here and make it its own module. However, I recommend that you
just use the new text type. Its simpler and faster.

---

# License

All code contributed to this repository is licensed under the standard MIT license:

Copyright 2011 ottypes library contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following condition:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


