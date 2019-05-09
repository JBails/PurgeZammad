# THIS SCRIPT WILL DESTROY CUSTOMERS HAVE CLOSED TICKETS OLDER THAN 30 DAYS, IGNORING MXDATA AND MAPWAY RELATED USERS

ticketless_customers = User.with_permissions('ticket.customer').where('email NOT LIKE ?', '%mapway.com%').where('email NOT LIKE ?', '%mxdata.co.uk%').where('updated_at < DATEADD(dd,-30,GETDATE())')
count = ticketless_customers.count

puts "#{count} customers without current tickets found, but tickets older than 30 days."
puts

ticketless_customers.find_each.with_index do |user, i|
  next if user.permissions?(%w[admin ticket.agent])
  next if user.id == 1

  display_name = user.fullname + (user.fullname == user.email ? '' : " (#{user.email})")
  print "[#{i.next}/#{count}] Delete customer #{display_name}? [y/N]"

  answer = STDIN
  puts

  if answer != 'y'
    puts "  Skipping #{display_name}"
    next
  end

  User.transaction do
    begin
      user.destroy!
      puts "  #{display_name} deleted."
    rescue => e
      puts "  #{display_name} could not be deleted: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end

#ticketless_customers.find_each.with_index do |user, i|
#  next if user.permissions?(%w[admin ticket.agent])
#  next if user.id == 1
#
#  display_name = user.fullname + (user.fullname == user.email ? '' : " (#{user.email})")
#  
#  User.transaction do
#    begin
#      user.destroy!
#      puts "  #{display_name} deleted."
#    rescue => e
#      puts "  #{display_name} could not be deleted: #{e.message}"
#      raise ActiveRecord::Rollback
#   next
#    end
#  end
#end
