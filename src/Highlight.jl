module Highlight

import Revise

module SQL

import Crayons

const SYNTAX = Dict{Symbol,Vector{String}}(
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

const CRAYONS = Dict{Symbol,Crayons.Crayon}(
  :ACTIONS      => Crayons.crayon"light_magenta",
  :KEYWORDS     => Crayons.crayon"cyan",
  :OPERATORS    => Crayons.crayon"light_red",
  :OTHER        => Crayons.crayon"blue",
  :CONDITIONAL  => Crayons.crayon"magenta",
  :VALUES       => Crayons.crayon"green",
  :JOINS        => Crayons.crayon"yellow",
  :SPECIAL      => Crayons.crayon"red",
  :TYPES        => Crayons.crayon"light_green"
)

end # module SQL

import Crayons
import .SQL

function highlight(s::String, m::Module = SQL)
  for (key, word_list) in m.SYNTAX
    for word in word_list
      s = replace(s, Regex(word, "i") => string(m.CRAYONS[key], word, Crayons.crayon"default"))
    end
  end

  s = replace(replace(replace(s, r"\"[a-zA-Z]*\"" => s"---->\0<----"), "---->\"" => string("\"", Crayons.crayon"green")), "\"<----" => string("\"", Crayons.crayon"default"))
  s = replace(replace(replace(s, r"\"[a-zA-Z_]*\"" => s"---->\0<----"), "---->\"" => string("\"", Crayons.crayon"magenta")), "\"<----" => string("\"", Crayons.crayon"default"))

  s = replace(s, "\"" => string(m.CRAYONS[:SPECIAL], "\"", Crayons.crayon"default"))
  s = replace(s, "'" => string(m.CRAYONS[:SPECIAL], "'", Crayons.crayon"default"))
  s = replace(s, "`" => string(m.CRAYONS[:SPECIAL], "`", Crayons.crayon"default"))
  s = replace(s, "*" => string(m.CRAYONS[:SPECIAL], "*", Crayons.crayon"default"))
  s = replace(s, "." => string(m.CRAYONS[:SPECIAL], ".", Crayons.crayon"default"))

  s
end

end
