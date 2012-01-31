Cursor = require 'cursor'
Range = require 'range'
Template = require 'template'
$$ = require 'template/builder'

module.exports =
class Selection extends Template
  content: ->
    @div()

  viewProperties:
    anchor: null
    modifyingSelection: null
    regions: null

    initialize: (@editor) ->
      @regions = []
      @cursor = @editor.cursor
      @cursor.on 'cursor:position-changed', =>
        if @modifyingSelection
          @updateAppearance()
        else
          @clearSelection()

    clearSelection: ->
      @anchor = null
      @updateAppearance()

    bufferChanged: (e) ->
      @cursor.setPosition(e.postRange.end)

    updateAppearance: ->
      @clearRegions()

      range = @getRange()
      return if range.isEmpty()

      rowSpan = range.end.row - range.start.row

      if rowSpan == 0
        @appendRegion(1, range.start, range.end)
      else
        @appendRegion(1, range.start, null)
        if rowSpan > 1
          @appendRegion(rowSpan - 1, { row: range.start.row + 1, column: 0}, null)
        @appendRegion(1, { row: range.end.row, column: 0 }, range.end)

    appendRegion: (rows, start, end) ->
      { lineHeight, charWidth } = @editor
      css = {}
      css.top = start.row * lineHeight
      css.left = start.column * charWidth
      css.height = lineHeight * rows
      if end
        css.width = end.column * charWidth - css.left
      else
        css.right = 0

      region = $$.div(class: 'selection').css(css)
      @append(region)
      @regions.push(region)

    clearRegions: ->
      region.remove() for region in @regions
      @regions = []

    getRange: ->
      if @anchor
        new Range(@anchor.getPosition(), @cursor.getPosition())
      else
        new Range(@cursor.getPosition(), @cursor.getPosition())

    setRange: (range) ->
      @cursor.setPosition(range.start)
      @modifySelection =>
        @cursor.setPosition(range.end)

    insertText: (text) ->
      @editor.buffer.change(@getRange(), text)

    insertNewline: ->
      @insertText('\n')

    backspace: ->
      range = @getRange()

      if range.isEmpty()
        if range.start.column == 0
          return if range.start.row == 0
          range.start.column = @editor.buffer.getLine(range.start.row - 1).length
          range.start.row--
        else
          range.start.column--

      @editor.buffer.change(range, '')

    delete: ->
      range = @getRange()

      if range.isEmpty()
        if range.end.column == @editor.buffer.getLine(range.end.row).length
          return if range.end.row == @editor.buffer.numLines() - 1
          range.end.column = 0
          range.end.row++
        else
          range.end.column++

      @editor.buffer.change(range, '')

    isEmpty: ->
      @getRange().isEmpty()

    modifySelection: (fn) ->
      @placeAnchor()
      @modifyingSelection = true
      fn()
      @modifyingSelection = false

    placeAnchor: ->
      return if @anchor
      cursorPosition = @cursor.getPosition()
      @anchor = { getPosition: -> cursorPosition }

    selectRight: ->
      @modifySelection =>
        @cursor.moveRight()

    selectLeft: ->
      @modifySelection =>
        @cursor.moveLeft()

    selectUp: ->
      @modifySelection =>
        @cursor.moveUp()

    selectDown: ->
      @modifySelection =>
        @cursor.moveDown()

    selectToPosition: (position) ->
      @modifySelection =>
        @cursor.setPosition(position)

    moveCursorToLineEnd: ->
      @cursor.moveToLineEnd()

    moveCursorToLineStart: ->
      @cursor.moveToLineStart()

    copy: ->
      return if @isEmpty()

      text = @editor.buffer.getTextInRange @getRange()
      atom.native.writeToPasteboard text

