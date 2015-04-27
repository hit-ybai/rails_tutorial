# store infos in mysql
require 'mysql'

# mysql config info
MYSQL_HOST          = 'localhost'
MYSQL_USER          = 'root'
MYSQL_PASSWORD      = ''
MYSQL_DATABASE_NAME = 'to_do_list'

def database_connection
  # get or create the 'to_do_list' databse
  begin
    @database_connection ||=
      Mysql.new(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE_NAME)
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

# close the databse connection when this program halt
ObjectSpace.define_finalizer(self, proc { database_connection.close })

def to_do_list_model
  to_do_list_items = []
  query_result = database_connection.query('SELECT * FROM `to_do_list_item`;')
  query_result.num_rows.times { to_do_list_items << query_result.fetch_row }
  to_do_list_items
end

def new_to_do_list_item(opt = {})
  database_connection.query("INSERT INTO `to_do_list_item`
      (priority, content, created_at, updated_at)
      VALUES(\'#{opt[:priority].upcase}\',\'#{opt[:content]}\', null, null);")
end

def update_to_do_list_item(opt = {})
  database_connection.query("UPDATE `to_do_list_item`
    SET `priority` = \'#{opt[:priority].upcase}\',
        `content` = \'#{opt[:content]}\'
    WHERE `id` = \'#{opt[:id]}\'")
end

def next_step_to_do_list_item(id)
  query_result =
    database_connection.query("SELECT `status`
      FROM `to_do_list_item` WHERE (`id` =  \'#{id}\');")
  next_step_map = {
    :TODO     => 'DOING',
    :DOING    => 'FINISHED',
    :FINISHED => 'FINISHED'
  }
  new_status = next_step_map[query_result.fetch_row.shift.to_sym]
  database_connection.query("UPDATE `to_do_list_item`
    SET `status` = \'#{new_status}\' WHERE `id` = \'#{id}\'")
end

def to_do_list_items_view(to_do_list_items)
  puts '+----+-----------+----------+---------+-------------+-------------+'
  puts '| id || priority || content || status || create_at  || updated_at |'
  puts '+----+-----------+----------+---------+-------------+-------------+'
  to_do_list_items.each do |to_do_list_item|
    to_do_list_item.each { |attribute| print "| #{attribute} |" }
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

def index_controller
  to_do_list_items_view(to_do_list_model)
  help_view
  while message = input_view.split(' ')
    order = message.shift
    case order.upcase
    when 'ALL' then to_do_list_items_view(to_do_list_model)
    when 'ADD'
      new_to_do_list_item({
        :priority => message.shift,
        :content  => message.join(' ')
      })
    when 'NEXT_STEP'
      next_step_to_do_list_item(message.shift)
    when 'UPDATE'
      update_to_do_list_item({
        :id       => message.shift,
        :priority => message.shift,
        :content  => message.join(' ')
      })
    when 'HELP' then help_view
    when 'EXIT' then return
    end
  end
end

index_controller
