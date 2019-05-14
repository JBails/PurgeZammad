# THIS SCRIPT WILL DESTROY CUSTOMERS HAVE CLOSED TICKETS OLDER THAN 30 DAYS, IGNORING MXDATA AND MAPWAY RELATED USERS

ticketless_customers = User.with_permissions('ticket.customer').where('email NOT LIKE ?', '%mapway.com%').where('email NOT LIKE ?', '%mxdata.co.uk%').where("updated_at < NOW() - INTERVAL '30' DAY")
count = ticketless_customers.count

puts "#{count} customers without current tickets found, but with tickets older than 30 days."
puts

ticketless_customers.find_each.with_index do |user, i|
  next if user.permissions?(%w[admin ticket.agent])
  next if user.id == 1

  display_name = user.fullname + (user.fullname == user.email ? '' : " (#{user.email})")

  Ticket.where(customer: user).find_each do |ticket|
    puts "  Deleting ticket #{ticket.number}..."
    ticket.destroy
  end

  puts "  Removing references for user with E-Mail #{user.email}..."
  ActivityStream.where(created_by_id: user.id).update_all(created_by_id: 1)
  History.where(created_by_id: user.id).update_all(created_by_id: 1)
  Ticket::Article.where(created_by_id: user.id).update_all(created_by_id: 1)
  Ticket::Article.where(updated_by_id: user.id).update_all(updated_by_id: 1)
  Store.where(created_by_id: user.id).update_all(created_by_id: 1)
  StatsStore.where(created_by_id: user.id).update_all(created_by_id: 1)
  Tag.where(created_by_id: user.id).update_all(created_by_id: 1)
  if OnlineNotification.find_by(user_id: user.id)==""
    OnlineNotification.find_by(user_id: user.id).destroy!
  end
  
  User.transaction do
    begin
      user.destroy!
      puts "  #{display_name}/#{user.email} deleted."
    rescue => e
      puts "  #{display_name}/#{user.email} could not be deleted: #{e.message}"
      raise ActiveRecord::Rollback
   next
    end
  end
end
