# store infos in mysql
require 'mysql'
require 'active_record'
# mysql config info
MYSQL_HOST          = 'localhost'
MYSQL_USER          = 'root'
MYSQL_PASSWORD      = ''
MYSQL_DATABASE_NAME = 'to_do_list'

# if this db dose not exsit, create it.
begin
  Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE_NAME)
rescue MysqlError => e
  Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD).query("CREATE DATABASE #{MYSQL_DATABASE_NAME};")
end

# use active record to connect to the db
ActiveRecord::Base.establish_connection(  
  :adapter  => "mysql",
  :username => MYSQL_USER,
  :host     => MYSQL_HOST,  
  :password => MYSQL_PASSWORD,
  :database => MYSQL_DATABASE_NAME
)

TODOLIST_TABLENAME = 'to_do_list_item'
DB_ENGINE_CHARSET_OPTIONS = 'ENGINE=InnoDB DEFAULT CHARSET=utf8'

# if to_do_list_item table dose not exsit, create it.
ActiveRecord::Migration.class_eval do
  unless ActiveRecord::Base.connection.table_exists? TODOLIST_TABLENAME
    create_table(TODOLIST_TABLENAME.to_sym,
      :options => DB_ENGINE_CHARSET_OPTIONS) do |t|
      t.column :priority,
        "ENUM('HIGH', 'LOW', 'NORMAL')",
        :null => false,
        :default => 'NORMAL'
      t.string :content,
        :null  => false,
        :limit => 128
      t.column :status,
        "ENUM('FINISHED','DOING','TODO')",
        :null => false,
        :default => 'TODO'
      t.timestamps
    end
  end
end

# a active record model ToDoList, ORM to 'to_do_list_item' table.
class ToDoList < ActiveRecord::Base
  self.table_name = TODOLIST_TABLENAME

  def to_next_step
    next_step_map = {
      :TODO     => 'DOING',
      :DOING    => 'FINISHED',
      :FINISHED => 'FINISHED'
    }
    @status = next_step_map[@status.to_sym]
    save
  end
end

def to_do_list_items_view(to_do_list_items)
  puts '+----+-----------+----------+---------+-------------+-------------+'
  puts '| id || priority || content || status || create_at  || updated_at |'
  puts '+----+-----------+----------+---------+-------------+-------------+'
  to_do_list_items.each do |to_do_list_item|
    ToDoList.column_names.each do |attribute|
      print "| #{to_do_list_item.send(attribute.to_sym)} |"
    end
    puts "\n|-----------------------------------------------------------------|"
  end
end

def help_view
  puts 'You can input:'
  puts "  'all'\n    [to show all to do list items]"
  puts "  'find id'\n     [to show a to do list item]"
  puts "  'add priority content'\n    [to add a new to do list item]"
  puts "  'update id priority content'\n    [to update a to do list item]"
  puts "  'next_step id'\n    [to update a to do list item status]"
  puts "  'help'\n    [to show a help message]"
  puts "  'exit'\n    [good bye]"
  puts 'ALERT: ROBUSTNESS is NOT under my consideration in this demo!'
end

def input_view
  print 'input: '
  gets
end

KEEP_RUNNING = true

def index_controller
  to_do_list_items_view(ToDoList.all)
  help_view
  while KEEP_RUNNING
    message = input_view.split(' ')
    order = message.shift
    case order.upcase
    when 'ALL' then to_do_list_items_view(ToDoList.all)
    when 'FIND' then to_do_list_items_view([] << ToDoList.find(message.shift))
    when 'ADD'
      to_do_list = ToDoList.new
      to_do_list.priority = message.shift
      to_do_list.content = message.join(' ')
      to_do_list.save
    when 'NEXT_STEP'
      to_do_list = ToDoList.find(message.shift)
      to_do_list.to_next_step
    when 'UPDATE'
      to_do_list = ToDoList.find(message.shift)
      to_do_list.priority = message.shift
      to_do_list.content = message.join(' ')
      to_do_list.save
    when 'HELP' then help_view
    when 'EXIT' then return
    end
  end
end

index_controller
