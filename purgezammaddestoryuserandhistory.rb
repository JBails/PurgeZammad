# Actual deletion, requires overview run before
User.joins(roles: :permissions).where(email: target_user_emails.map(&:downcase), roles: { active: true }, permissions: { name: 'ticket.customer', active: true }).where.not(id: 1).where('email NOT LIKE ?', '%mapway.com%').where('email NOT LIKE ?', '%mxdata.co.uk%').where("updated_at < NOW() - INTERVAL '30' DAY").find_each do |user|
 puts "Customer #{user.login}/#{user.email} has #{Ticket.where(customer_id: user.id).count} tickets"

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

 puts "  Deleting user #{user.login}/#{user.email}..."
 user.destroy
end
