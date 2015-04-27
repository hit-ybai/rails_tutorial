# store infos in mysql
require 'mysql'

# mysql config info
MYSQL_HOST          = 'localhost'
MYSQL_USER          = 'root'
MYSQL_PASSWORD      = ''
MYSQL_DATABASE_NAME = 'to_do_list'

class ToDoList

  def initialize(opts = {})
    self.class.meta_data.each do |attribute|
      self.class.send(:attr_accessor, attribute)
    end
    self.class.meta_data.each do |attribute|
      self.send("#{attribute}=".to_sym, opts[attribute.to_sym])
    end
  end

  def save
    @id ? save_update : save_insert
  end

  def save_insert
    self.class.database_connection.query("INSERT INTO `to_do_list_item`
      (priority, content) VALUES (\'#{@priority.upcase}\',\'#{@content}\');")
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

  class << self
    # get or create the 'to_do_list' databse

    def init_to_do_list_data_sql
      "CREATE TABLE `to_do_list_item` (
        `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
        `priority` ENUM('HIGH', 'LOW', 'NORMAL') NOT NULL DEFAULT 'NORMAL',
        `content` VARCHAR(128) NOT NULL,
        `status` ENUM('FINISHED','DOING','TODO') NOT NULL DEFAULT 'TODO',
        `created_at` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
          ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`) )ENGINE=InnoDB DEFAULT CHARSET=utf8;"
    end

    def init_db
      database_connection = Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD)
      database_connection.query("CREATE DATABASE #{MYSQL_DATABASE_NAME};")
      database_connection.query("USE #{MYSQL_DATABASE_NAME};")
      database_connection.query(init_to_do_list_data_sql)

      database_connection.query("INSERT INTO `to_do_list_item`
        (content, created_at, updated_at)
        VALUES ('Hello World', null, null);")
      database_connection
    end

    def database_connection
      begin
        @database_connection =
          Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE_NAME)
      rescue MysqlError => e
        if "Unknown database '#{MYSQL_DATABASE_NAME}'" == e.to_s
          @database_connection = init_db
        end
      end
    end

    def meta_data
      @meta_data ||= take_meta_data
    end

    def take_meta_data
      meta_data = []
      query_result = database_connection.query("SHOW COLUMNS FROM `to_do_list_item`;")
      query_result.num_rows.times{ meta_data << query_result.fetch_row.shift }
      meta_data
    end

    def find(id)
      query_result = database_connection.query("SELECT * FROM `to_do_list_item`
        WHERE (`id` =  \'#{id}\');").fetch_row
      create_hash = {}
      ToDoList.meta_data.each do |attribute|
        create_hash.merge!({ attribute.to_sym => query_result.shift })
      end
      ToDoList.new(create_hash)
    end

    def all
      to_do_list_items = []
      query_result = database_connection.query("SELECT * FROM `to_do_list_item`;")
      query_result.num_rows.times do
        current_item_hash  = {}
        current_item_query = query_result.fetch_row
        ToDoList.meta_data.each do |attribute|
          current_item_hash.merge!({ attribute.to_sym => current_item_query.shift })
        end
        to_do_list_items << ToDoList.new(current_item_hash)
      end
      to_do_list_items
    end

    # close the databse connection when gc
    ObjectSpace.define_finalizer(self, proc { database_connection.close })
  end
end



def to_do_list_items_view(to_do_list_items)
  puts '+----+-----------+----------+---------+-------------+-------------+'
  puts '| id || priority || content || status || create_at  || updated_at |'
  puts '+----+-----------+----------+---------+-------------+-------------+'
  to_do_list_items.each_with_index do |to_do_list_item, index|
    ToDoList.meta_data.each do |attribute|
      print '| #{to_do_list_item.send(attribute.to_sym)} |'
    end
    puts "\n|-----------------------------------------------------------------|"
  end
end

def help_view
  puts 'You can input:'
  puts "  'all'\n    [to show all to do list items]"
  puts "  'find id'\n     to show a to do list item]"
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
    when 'ALL'
      to_do_list_items_view(ToDoList.all)
    when 'FIND'
      to_do_list_items_view([] << ToDoList.find(message.shift))
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
    when 'HELP'
      help_view
    when 'EXIT' then return
    end
  end
end

index_controller
