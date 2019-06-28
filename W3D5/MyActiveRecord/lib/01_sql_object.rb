require_relative 'db_connection'
require 'byebug'
require 'active_support/inflector'
# require 'searchable'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.


class SQLObject
  # extend Searchable


  def self.columns
   if @columns == nil 
      @columns = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{self.table_name}
      SQL
      @columns = @columns[0].map {|ele| ele.to_sym}
   end
   @columns
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}") do
        attributes[col.to_sym]
      end
      define_method("#{col}=") do |val|
        attributes[col.to_sym] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    default = "#{self}"
    default.each_char.with_index do |char, i|
      
      if char == char.upcase
        default[i] = char.downcase
        
        default.insert(i, '_') unless i = 0
      end
    end
    default << 's'
  
    @table_name ||= default
  end

  def self.all
   results = DBConnection.execute(<<-SQL)
        SELECT
          #{self.table_name}.*
        FROM
          #{self.table_name}
      SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
        SELECT
          #{self.table_name}.*
        FROM
          #{self.table_name}
        WHERE
          id = ?
      SQL
      return nil if result.empty?
      result.map do |params|
        return self.new(params)
      end
     
  end

  def initialize(params = {})
    
    params.each do |k, v|
      # debugger
      raise "unknown attribute '#{k}'" unless self.class.send(:columns).include?(k.to_sym)
      k = k.to_sym unless k.is_a?(Symbol)
      # self.send(:attributes)[k] = v
      send("#{k}=", v)
      # debugger
      1 + 1
    end
  end

  def attributes
    @attributes ||= {}
    
  end

  def attribute_values
    vals = []
    
    cols = self.class.send(:columns)
    cols.each do |col|
      #debugger
      vals << self.send(col)
    end
    vals
  end

  def insert
    
    col_names = self.class.send(:columns)[1..-1]
    question_marks = []
    col_names.length.times {question_marks << '?'}
    q_str = question_marks.join(', ')
    col_str = col_names.join(', ')
    attrs = self.send(:attribute_values)[1..-1]
    sym_strings = attrs.map do |sym|
      sym.to_s
    end
    #debugger
    # DBConnection.execute(<<-SQL, #{attr_str})
    #   INSERT INTO
    #     #{self.table_name} (#{col_str})
    #   VALUES
    #     (#{q_str})
    # SQL
    DBConnection.execute(<<-SQL, *sym_strings)
      INSERT INTO
        #{self.class.table_name} (#{col_str})
      VALUES
      (#{q_str})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.send(:columns)[1..-1]
    # question_marks = []
    # col_names.length.times {question_marks << '?'}
    # q_str = question_marks.join(', ')
    new_cols = col_names.map {|col| "#{col} = ?"}
    col_str = new_cols.join(', ')

    attrs = self.send(:attribute_values).drop(1)
    sym_strings = attrs.map do |sym|
      sym.to_s
    end
    debugger
    DBConnection.execute(<<-SQL, *sym_strings)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_str}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    id == nil ? insert : update
  end
end
