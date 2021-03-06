
Stringifier = (csv) ->
  @csv = csv
  @
  
###
Write a line to the written stream.
Line may be an object, an array or a string
Preserve is for line which are not considered as CSV data
###
Stringifier.prototype.write = (line, preserve) ->
  return if typeof line is 'undefined' or line is null
  # Emit the record
  unless preserve
    try @csv.emit 'record', line, @csv.state.count
    catch e then return @csv.error e
    # Convert the record into a string
    line = @csv.stringifier.stringify line
  # Emit the csv
  @csv.emit 'data', line
  @csv.state.countWriten++ unless preserve
  true

Stringifier.prototype.stringify = (line) ->
  columns = @csv.options.to.columns or @csv.options.from.columns
  delimiter = @csv.options.to.delimiter or @csv.options.from.delimiter
  quote = @csv.options.to.quote or @csv.options.from.quote
  escape = @csv.options.to.escape or @csv.options.from.escape
  if typeof line is 'object'
    unless Array.isArray line
      _line = []
      if columns
        for i in [0...columns.length]
          column = columns[i]
          _line[i] = if (typeof line[column] is 'undefined' or line[column] is null) then '' else line[column]
      else
        for column of line
          _line.push line[column]
      line = _line
      _line = null
    else if @csv.options.to.columns
      # We are getting an array but the user want specified output columns. In
      # this case, we respect the columns indexes
      line.splice @csv.options.to.columns.length
    if Array.isArray line
      newLine = if @csv.state.countWriten then @csv.options.to.lineBreaks or "\n" else ''
      for i in [0...line.length]
        field = line[i]
        if typeof field is 'string'
          # fine 99% of the cases, keep going
        else if typeof field is 'number'
          # Cast number to string
          field = '' + field
        else if typeof field is 'boolean'
          # Cast boolean to string
          field = if field then '1' else ''
        else if field instanceof Date
          # Cast date to timestamp string
          field = '' + field.getTime()
        if field
          containsdelimiter = field.indexOf(delimiter) >= 0
          containsQuote = field.indexOf(quote) >= 0
          containsLinebreak = field.indexOf("\r") >= 0 or field.indexOf("\n") >= 0
          if containsQuote
            regexp = new RegExp(quote,'g')
            field = field.replace(regexp, escape + quote)
          if containsQuote or containsdelimiter or containsLinebreak or @csv.options.to.quoted
            field = quote + field + quote
          newLine += field
        if i isnt line.length - 1
          newLine += delimiter
      line = newLine
  else if typeof line is 'number'
    line = ''+line
  line


module.exports = (csv) -> new Stringifier csv