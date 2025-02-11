
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(homephone)
  homephone.gsub!(/\D/, '') #remove all non-digits

  if homephone.length < 10
    homephone = 'bad number'
  elsif homephone.length > 11
    homephone = 'bad number'
  elsif homephone.length == 11
    if homephone[0]!= 1
     'bad number'
    else
      homephone[0..9]
    end
  else 
    homephone
  end
end

hours_hash = (0..23).each_with_object({}) { |hour, hash| hash[hour] ||= 0 }


def most_popular_hour(hour, hours_hash)
  hours_hash[hour] += 1
 
 @best_hour = hours_hash.max_by { |k,v| v }[0]
  
end

days_hash = (0..6).each_with_object({}) { |day, hash| hash[day] ||= 0 }

def most_popular_day(day_of_week, days_hash)
  days_hash[day_of_week] += 1
  @best_day = days_hash.max_by { |k,v| v }[0]
  days = {0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 
          4 => "Thursday", 5 => "Friday", 6 => "Saturday"}
  @print_best_day = days[@best_day] if days.key?(@best_day)
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(row[:homephone])

  date = DateTime.strptime(row[:regdate],'%m/%d/%y %H:%M')
  hour = date.hour
  day_of_week = date.wday

  most_popular_hour(hour, hours_hash)

  most_popular_day(day_of_week, days_hash)

  puts "#{id}, #{name}, #{zipcode}, #{phone}, #{hour}, #{day_of_week}"

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

puts "#{@best_hour} is the peak registration hour"
puts "#{@print_best_day} is the peak registration day"
