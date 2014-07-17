# Random op generator for the embedded text0 OT type. This is used by the fuzzer
# test.

{randomReal, randomWord} = require 'ot-fuzzer'
text0 = require '../lib/text0'

module.exports = genRandomOp = (docStr) ->
  pct = 0.9

  op = []

  while randomReal() < pct
#    console.log "docStr = #{i docStr}"
    pct /= 2
    
    if randomReal() > 0.5
      # Append an insert
      pos = Math.floor(randomReal() * (docStr.length + 1))
      str = randomWord() + ' '
      text0._append op, {i:str, p:pos}
      docStr = docStr[...pos] + str + docStr[pos..]
    else
      # Append a delete
      pos = Math.floor(randomReal() * docStr.length)
      length = Math.min(Math.floor(randomReal() * 4), docStr.length - pos)
      text0._append op, {d:docStr[pos...(pos + length)], p:pos}
      docStr = docStr[...pos] + docStr[(pos + length)..]
  
#  console.log "generated op #{i op} -> #{i docStr}"
  [op, docStr]
