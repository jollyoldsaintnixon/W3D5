# require 'byebug'
# require_relative 'db_connection'
# require_relative '01_sql_object'


# module Searchable 

#   def where(params)
#     where_line = params.keys.map {|k| "#{k} = ?"}.join(" AND ")
#     debugger
#     puts "helo"
#     result = DBConnection.execute(<<-SQL, *params.values)
#       SELECT
#         *
#       FROM
#         #{self.class.table_name}
#       WHERE
#         #{where_line}
#     SQL
#     result.map do |params|
#       self.new(params)
#     end
#   end
  
# end