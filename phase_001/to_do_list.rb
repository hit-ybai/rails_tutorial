# store infos in file
require 'csv'
require 'mysql'
require 'pry'

# mysql config info
MYSQL_HOST          = 'localhost'
MYSQL_USER          = 'root'
MYSQL_PASSWORD      = ''
MYSQL_DATABASE_NAME = 'to_do_list'

def database_connection
# get or create the 'to_do_list' databse
  begin
    @database_connection ||= Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE_NAME)
  rescue Exception => e
    if "Unknown database '#{MYSQL_DATABASE_NAME}'" == e.to_s
      @database_connection = Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD)
      @database_connection.query("CREATE DATABASE #{MYSQL_DATABASE_NAME};")
      @database_connection.query("USE #{MYSQL_DATABASE_NAME};")
      @database_connection.query("CREATE TABLE `to_do_list_item` (
                                    `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
                                    `priority` ENUM('HIGH', 'LOW', 'NORMAL') NOT NULL DEFAULT 'NORMAL',
                                    `content` VARCHAR(128) NOT NULL,                                          
                                    `status` ENUM('FINISHED','DOING','TODO') NOT NULL DEFAULT 'TODO',
                                    `created_at` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
                                    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                    PRIMARY KEY (`id`) )ENGINE=InnoDB DEFAULT CHARSET=utf8;")

      @database_connection.query("INSERT INTO `to_do_list_item` (content) VALUES ('Hello World');")
      return @database_connection
    end
  end
end

# close the databse connection when this program halt
ObjectSpace.define_finalizer(self, proc { database_connection.close })

def load_data
  to_do_list_items = []
  query_result = database_connection.query("SELECT * FROM `to_do_list_item`;")
  n_rows = query_result.num_rows
  n_rows.times { to_do_list_items << query_result.fetch_row }
  to_do_list_items
end

def to_do_list_model
  @to_do_list_model ||= load_data
end

def to_do_list_items_view(to_do_list_items)
  puts "+----+-----------+----------+---------+-------------+-------------+"
  puts "| id || priority || content || status || updated_at || created_at |"
  puts "+----+-----------+----------+---------+-------------+-------------+"
  to_do_list_items.each_with_index do |to_do_list_item, index| 
    to_do_list_item.each { |attribute| print "| #{attribute} |" } 
    puts "\n|-----------------------------------------------------------------|"
  end
end

def help_view
  puts "You can input:"
  puts "  'all'\n    [to show all to do list items]"
  puts "  'add priority content'\n    [to add a new to do list item]"
  puts "  'update id priority content'\n    [to update a to do list item]"
  puts "  'find id'\n    [to show a specific to do list item]"
  puts "  'help'\n    [to show a help message]"
end

def index_controller
  to_do_list_items_view(to_do_list_model)
  help_view
end

index_controller