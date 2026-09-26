; rainbow-delimiters.nvim ships no Fortran query. Brackets appear as direct
; children of 20+ node types (argument_list, kind, type_qualifier,
; parenthesized_expression, size, derived_type, parameters, array_literal,
; ...), so match any node that owns a bracket pair instead of listing them.

(_ "(" @delimiter ")" @delimiter @sentinel) @container

(_ "[" @delimiter "]" @delimiter @sentinel) @container

(_ "(/" @delimiter "/)" @delimiter @sentinel) @container
