# Solve anagrams

{ readFileSync: readFile } = require 'fs'

{ without, argv } = require './common'

more = 0

argv = argv
  .filter (w) ->
    if w is '-m'
      more++
      false
    else
      true

argStr = argv.join ' '

letters = argStr
  .toLowerCase()
  .match /[a-z]/g

validWord  = (w) -> w.length <= 11 and not w.match /[^a-z]/

dictionaryName = (name = './words') ->
  module.exports.dictionary =
    readFile name
      .toString()
      .split  '\n'
      .filter validWord
      .sort   (a, b) -> b.length - a.length

contains = (letters, word) ->
  return false unless letters.length >= word.length

  if -1 < idx = letters.indexOf char = word[0]
    return word.length is 1 or contains without(idx, letters), word[1..]

findWords = (letters, more = 0) ->
  foundLen = 0

  for word in module.exports.dictionary when contains letters, word
    foundLen or= word.length

    if (word.length + more) < foundLen
      break

    word

Object.assign module.exports, {findWords, dictionaryName, contains}
