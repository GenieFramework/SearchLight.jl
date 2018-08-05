module Highlight

module SQL

using Crayons

const SYNTAX = Dict(
  :ACTIONS   =>   ["ALTER", "CREATE", "DELETE", "DROP", "INSERT", "EXPLAIN", "SELECT", "TRUNCATE", "UPDATE"],
  :KEYWORDS  =>   ["BEGIN", "CONSTRAINT", "FROM", "GROUP", "HAVING", "ORDER",
                  "ROLLBACK", "SET", "TABLE", "TRANSACTION", "UNION", "VIEW"],
  :OPERATORS =>   ["AND", "BETWEEN", "IN", "XOR", "OR ", "!=", "<>", ">=", "<=", ">", "<", "/"],
  :OTHER =>       ["ASC", "AS ", "BY", "DESC", "OFFSET", "ON"],
  :CONDITIONAL => ["CASE", "ELSE", "ELSEIF", "EXISTS", "IF", "NOT", "THEN", "WHERE"],
  :VALUES =>      ["FALSE", "KEY", "NULL", "PRIMARY", "TRUE", "VALUE"],
  :JOINS =>       ["INNER", "JOIN", "LEFT", "OUTER", "RIGHT"],
  :TYPES =>       ["BOOLEAN", "DATE", "SERIAL", "TEXT", "VARCHAR"],
)

const CRAYONS = Dict(
  :ACTIONS      => crayon"light_magenta",
  :KEYWORDS     => crayon"cyan",
  :OPERATORS    => crayon"light_red",
  :OTHER        => crayon"blue",
  :CONDITIONAL  => crayon"magenta",
  :VALUES       => crayon"green",
  :JOINS        => crayon"yellow",
  :SPECIAL      => crayon"red",
  :TYPES        => crayon"light_green",
)

end

using Crayons
using .SQL

function highlight(s::String, m::Module = SQL)
  for (key, word_list) in m.SYNTAX
    for word in word_list
      s = replace(s, Regex(word, "i") => string(m.CRAYONS[key], word, crayon"default"))
    end
  end

  s = replace(replace(replace(s, r"\"[a-zA-Z]*\"" => s"---->\0<----"), "---->\"" => string("\"", crayon"green")), "\"<----" => string("\"", crayon"default"))
  s = replace(replace(replace(s, r"\"[a-zA-Z_]*\"" => s"---->\0<----"), "---->\"" => string("\"", crayon"magenta")), "\"<----" => string("\"", crayon"default"))

  s = replace(s, "\"" => string(m.CRAYONS[:SPECIAL], "\"", crayon"default"))
  s = replace(s, "'" => string(m.CRAYONS[:SPECIAL], "'", crayon"default"))
  s = replace(s, "`" => string(m.CRAYONS[:SPECIAL], "`", crayon"default"))
  s = replace(s, "*" => string(m.CRAYONS[:SPECIAL], "*", crayon"default"))
  s = replace(s, "." => string(m.CRAYONS[:SPECIAL], ".", crayon"default"))

  s
end

end
