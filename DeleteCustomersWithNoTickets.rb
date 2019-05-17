# This script will delete all users that do not have an assigned ticket (open or closed), with no regards as to how long they haven't had a ticket
# i.e. doesn't care if the last ticket was deleted 30 seconds or 30 days ago

ticketless_customers = User.with_permissions('ticket.customer').where('email NOT LIKE ?', '%mapway.com%').where('email NOT LIKE ?', '%mxdata.co.uk%').where('id NOT IN (SELECT customer_id FROM tickets)')
count = ticketless_customers.count

puts "#{count} customers without tickets found."
puts

ticketless_customers.find_each.with_index do |user, i|
  next if user.permissions?(%w[admin ticket.agent])
  next if user.id == 1

  display_name = user.fullname + (user.fullname == user.email ? '' : " (#{user.email})")
  
  User.transaction do
    begin
      user.destroy!
      puts "  #{display_name} deleted."
    rescue => e
      puts "  #{display_name} could not be deleted: #{e.message}"
      raise ActiveRecord::Rollback
    next
    end
  end
end
