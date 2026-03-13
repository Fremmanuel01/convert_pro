class CleanupConversionsJob < ApplicationJob
  queue_as :default

  def perform
    # 1. Clean up Free user conversions older than 24 hours
    free_threshold = 24.hours.ago
    free_users_conversions = Conversion.joins(:user)
                                       .where(users: { plan: User.plans[:free] })
                                       .where("conversions.created_at < ?", free_threshold)
    
    deleted_free = purge_conversions(free_users_conversions)

    # 2. Clean up Pro user conversions older than 30 days
    pro_threshold = 30.days.ago
    pro_users_conversions = Conversion.joins(:user)
                                      .where(users: { plan: User.plans[:pro] })
                                      .where("conversions.created_at < ?", pro_threshold)
    
    deleted_pro = purge_conversions(pro_users_conversions)
    
    Rails.logger.info("Cleanup Job Completed: Purged #{deleted_free} Free files and #{deleted_pro} Pro files.")
  end

  private

  def purge_conversions(conversions)
    count = conversions.count
    conversions.find_each do |conversion|
      # Destroy explicitly to trigger ActiveStorage cascading purges mapped in models
      conversion.destroy
    end
    count
  end
end
