# store infos in file
require 'csv'
require 'digest'

# attributes of a to do item record
METADATA = %w(id priority content update_at status)
INIT_TODO_ITEM = ['0', 'low', 'Hello World', Time.now.to_s, 'TODO']

def init_csv_file
  return if File.exist?('database.csv')
  CSV.open('database.csv', 'w') do |data|
    data << METADATA
    data << INIT_TODO_ITEM
  end
end

def load_data
  init_csv_file

  to_do_list_items = []
  csv = CSV.read('database.csv')
  csv.each do |row|
    to_do_item = {}
    METADATA.each_with_index do |attribute, idx|
      to_do_item.merge!(attribute.to_sym => row[idx])
    end
    to_do_list_items << to_do_item
  end
  to_do_list_items
end

def to_do_list_model
  @to_do_list_model ||= load_data
end

def new_to_do_list_item(opt = {})
  priority = opt[:priority]
  content  = opt[:content]
  to_do_list_model << {
    :id        => Digest::MD5.hexdigest(Time.now.to_s),
    :priority  => priority,
    :content   => content,
    :update_at => Time.now.to_s,
    :status    => 'TODO'
  }
end

def next_step_to_do_list_item(id)
  current_to_do_list_item =
    to_do_list_model.select { |to_do_list_item| to_do_list_item[:id] == id }
  next_step_map = {
    :TODO     => 'DOING',
    :DOING    => 'FINISHED',
    :FINISHED => 'FINISHED'
  }
  current_to_do_list_item.first[:status] =
    next_step_map[current_to_do_list_item.first[:status].to_sym]
end

def update_to_do_list_item(opt = {})
  id       = opt[:id]
  priority = opt[:priority]
  content  = opt[:content]
  current_to_do_list_item =
    to_do_list_model.select { |to_do_list_item| to_do_list_item[:id] == id }
  current_to_do_list_item.first[:priority] = priority
  current_to_do_list_item.first[:content] = content
end

def to_do_list_items_view(to_do_list_items)
  to_do_list_items.each_with_index do |to_do_list_item, index|
    puts '----------------------------' if 1 == index
    METADATA.each_with_index do |attribute|
      print "| #{to_do_list_item[attribute.to_sym]} |"
    end
    puts
  end
end

def exit_and_save
  CSV.open('database.csv', 'w') do |data|
    to_do_list_model.each do |to_do_list_item|
      data << to_do_list_item.values
    end
  end
  exit
end

def help_view
  puts 'You can input:'
  puts "  'all'\n    [to show all to do list items]"
  puts "  'add priority content'\n    [to add a new to do list item]"
  puts "  'update id priority content'\n    [to update a to do list item]"
  puts "  'next_step id'\n    [to update a to do list item status]"
  puts "  'help'\n    [to show a help message]"
  puts "  'exit'\n    [exit and save]"
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
    when 'EXIT' then exit_and_save
    end
  end
end

index_controller
