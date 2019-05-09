ticketless_customers = User.with_permissions('ticket.customer').where('email NOT %@mapway.com').where('email NOT %@mxdata.co.uk').where('id NOT IN (SELECT customer_id FROM tickets)')
count = ticketless_customers.count

puts "#{count} customers without tickets found."
puts

ticketless_customers.find_each.with_index do |user, i|
  next if user.permissions?(%w[admin ticket.agent])
  next if user.id == 1

  display_name = user.fullname + (user.fullname == user.email ? '' : " (#{user.email})")
  print "[#{i.next}/#{count}] Delete customer #{display_name}? [y/N]"

  answer = STDIN.getch.downcase
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
