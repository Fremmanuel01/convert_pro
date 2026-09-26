class CleanupConversionsJob < ApplicationJob
  queue_as :default

  Retention = AppLimits::Retention

  # Enforces the document lifecycle / retention policy. Runs daily (config/recurring.yml).
  #
  # Retention (see AppLimits::Retention):
  #   - Free user conversions:  purged after FREE_HOURS
  #   - Guest (unassigned):     purged after GUEST_HOURS
  #   - Pro user conversions:   purged after PRO_DAYS
  #   - Failed conversions:     purged after FAILED_HOURS (no value in keeping them)
  #   - Abandoned in-flight:    reclaimed after ABANDONED_HOURS (marked failed + refunded)
  #
  # Destroying a Conversion cascades Active Storage purges (input_files + output_file)
  # to whichever backend is configured (R2 / Cloudinary / disk). Every step is
  # idempotent and safe to re-run.
  def perform
    reclaimed = reclaim_abandoned!

    purged  = 0
    purged += purge(guest_conversions)
    purged += purge(free_conversions)
    purged += purge(pro_conversions)
    purged += purge(stale_failed_conversions)

    Rails.logger.info("CleanupConversionsJob: reclaimed #{reclaimed} abandoned, purged #{purged} conversions.")
  end

  private

  def free_conversions
    Conversion.joins(:user)
              .where(users: { plan: User.plans[:free] })
              .where("conversions.created_at < ?", Retention::FREE_HOURS.hours.ago)
  end

  def pro_conversions
    Conversion.joins(:user)
              .where(users: { plan: User.plans[:pro] })
              .where("conversions.created_at < ?", Retention::PRO_DAYS.days.ago)
  end

  def guest_conversions
    Conversion.where(user_id: nil)
              .where("created_at < ?", Retention::GUEST_HOURS.hours.ago)
  end

  def stale_failed_conversions
    Conversion.where(status: Conversion.statuses[:failed])
              .where("created_at < ?", Retention::FAILED_HOURS.hours.ago)
  end

  # Mark long-stuck pending/processing conversions failed and refund their unit.
  def reclaim_abandoned!
    cutoff = Retention::ABANDONED_HOURS.hours.ago
    scope  = Conversion.where(status: [Conversion.statuses[:pending], Conversion.statuses[:processing]])
                       .where("updated_at < ?", cutoff)

    count = 0
    scope.find_each do |conversion|
      conversion.update!(status: :failed, error_message: "Processing was interrupted. Please try again.")
      conversion.refund_usage!
      count += 1
    end
    count
  end

  def purge(scope)
    count = 0
    scope.find_each do |conversion|
      conversion.destroy
      count += 1
    end
    count
  end
end
