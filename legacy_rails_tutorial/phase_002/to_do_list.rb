# store infos in mysql
require 'mysql'

# mysql config info
MYSQL_HOST          = 'localhost'
MYSQL_USER          = 'root'
MYSQL_PASSWORD      = ''
MYSQL_DATABASE_NAME = 'to_do_list'
METADATA            = %i(id priority content status created_at updated_at)

class ToDoList
  attr_accessor :id, :priority, :content, :status, :created_at, :updated_at

  class << self
    # get or create the 'to_do_list' databse
    def database_connection
      begin
        @database_connection ||=
          Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE_NAME)
      rescue MysqlError => e
        if "Unknown database '#{MYSQL_DATABASE_NAME}'" == e.to_s
          @database_connection =
            Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD)
          @database_connection.query("CREATE DATABASE #{MYSQL_DATABASE_NAME};")
          @database_connection.query("USE #{MYSQL_DATABASE_NAME};")
          @database_connection.query("CREATE TABLE `to_do_list_item` (
            `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
            `priority` ENUM('HIGH', 'LOW', 'NORMAL') NOT NULL DEFAULT 'NORMAL',
            `content` VARCHAR(128) NOT NULL,
            `status` ENUM('FINISHED','DOING','TODO') NOT NULL DEFAULT 'TODO',
            `created_at` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
              ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`) )ENGINE=InnoDB DEFAULT CHARSET=utf8;")

          @database_connection.query("INSERT INTO `to_do_list_item`
            (content, created_at, updated_at)
            VALUES ('Hello World', null, null);")
          return @database_connection
        end
      end
    end

    def find(id)
      query_result = database_connection.query("SELECT * FROM `to_do_list_item`
        WHERE (`id` =  \'#{id}\');").fetch_row
      ToDoList.new(Hash[METADATA.zip(query_result)])
    end

    def all
      to_do_list_items = []
      query_result =
        database_connection.query('SELECT * FROM `to_do_list_item`;')
      query_result.num_rows.times do
        current_item_hash  = {}
        current_item_query = query_result.fetch_row
        METADATA.each do |attribute|
          current_item_hash[attribute] = current_item_query.shift
        end
        to_do_list_items << ToDoList.new(current_item_hash)
      end
      to_do_list_items
    end

    # close the databse connection when gc
    ObjectSpace.define_finalizer(self, proc { database_connection.close })
  end

  def initialize(opts = {})
    @id         = opts[:id]
    @priority   = opts[:priority]
    @content    = opts[:content]
    @status     = opts[:status]
    @created_at = opts[:created_at]
    @updated_at = opts[:updated_at]
  end

  def save
    @id ? save_update : save_insert
  end

  def save_insert
    self.class.database_connection.query("INSERT INTO `to_do_list_item`
      (priority, content, created_at, updated_at)
      VALUES(\'#{@priority.upcase}\',\'#{@content}\', null, null);")
  end

  def save_update
    self.class.database_connection.query("UPDATE `to_do_list_item`
      SET `priority` = \'#{@priority.upcase}\', `content` = \'#{@content}\',
      `status` = \'#{@status}\' WHERE `id` = \'#{id}\'")
  end

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
    METADATA.each do |attribute|
      print "| #{to_do_list_item.send(attribute)} |"
    end
    puts "\n|-----------------------------------------------------------------|"
  end
end

def help_view
  puts 'You can input:'
  puts "  'all'\n    [to show all to do list items]"
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
