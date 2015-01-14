# store infos in file
require 'csv'

# attributes of a to do item record
METADATA = %w('id', 'priority', 'content', 'update_at', 'status')
INTI_TODO_ITEM = ['1', 'low', 'Hello World', Time.now, 'to do']

def init_csv_file
  return if File.exist?('database.csv')
  CSV.open('database.csv', 'w') do |data|
    data << METADATA
    data << INTI_TODO_ITEM
  end
end

def load_data
  init_csv_file

  to_do_list_items = []
  csv = CSV.read('database.csv')
  csv.each do |row|
    to_do_item = {}
    METADATA.each_with_index { |attribute, idx| to_do_item.merge!("#{attribute}" => row[idx]) }
    to_do_list_items << to_do_item
  end
  to_do_list_items
end

def to_do_list_model
  @to_do_list_model ||= load_data
end

def to_do_list_items_view(to_do_list_items)
  to_do_list_items.each_with_index do |to_do_list_item, index|
    puts "----------------------------" if 1 == index

    METADATA.each_with_index do |attribute, idx|
      print 0 == idx ? "#{to_do_list_item[attribute]}" : " | #{to_do_list_item[attribute]}"
    end
    puts
  end
end

def help_view
  puts
  puts "-----all of those features will be supported in the next version-----"
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
