require 'csv'

def CSV.guess_column_separator(contents)
  contents.index("\t") ? "\t" : ","
end