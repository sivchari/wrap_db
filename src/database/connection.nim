type
  GoDBConnection = pointer
  QueryRows = pointer

proc dbQuote(s: string): string =
  ## DB quotes the string.
  result = newStringOfCap(s.len + 2)
  result.add "'"
  for c in items(s):
    # see https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html#mysql-escaping
    case c
    of '\0': result.add "\\0"
    of '\b': result.add "\\b"
    of '\t': result.add "\\t"
    of '\l': result.add "\\n"
    of '\r': result.add "\\r"
    of '\x1a': result.add "\\Z"
    of '"': result.add "\\\""
    of '\'': result.add "\\'"
    of '\\': result.add "\\\\"
    of '_': result.add "\\_"
    else: result.add c
  add(result, '\'')

proc dbFormat(formatstr: string, args: varargs[string, `$`]): string =
  result = ""
  var count = 0
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[count]))
      inc(count)
    else:
      add(result, c)

proc open*(driverName, dataSourceName: cstring):GoDBConnection {.dynlib: "../../sql.so", importc: "Open".}
proc ping*(uptr: GoDBConnection):cstring {.dynlib: "../../sql.so", importc: "Ping".}
proc queryExec(uptr: GoDBConnection, query: cstring):QueryRows {.dynlib: "../../sql.so", importc: "Query1".}

proc query*(uptr: GoDBConnection, query: string, args: varargs[string, `$`]):QueryRows =
  let q = dbFormat(query, args)
  uptr.queryExec(q)