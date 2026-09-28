class ConversionLimiter
  FREE_LIMIT = 5

  def initialize(user)
    @user = user
  end

  def can_convert?
    return true if @user.nil?
    return true if unlimited?
    @user.free? && !limit_reached?
  end

  def unlimited?
    !!(@user&.pro? && @user&.active?)
  end

  def limit_reached?
    return false if @user.nil?
    @user.conversions_count >= FREE_LIMIT
  end

  def remaining
    return :unlimited if @user.nil?
    return :unlimited if unlimited?

    left = FREE_LIMIT - @user.conversions_count
    left > 0 ? left : 0
  end

  # Atomically consume ONE unit of quota. Returns true if a unit was claimed
  # (or the user is anonymous / unlimited), false if the free limit is already
  # reached. The single conditional UPDATE is race-safe: under concurrent
  # requests only one caller can move the counter across the limit boundary.
  def claim!
    return true if @user.nil?
    return true if unlimited?
    return false unless @user.free? # e.g. lapsed Pro: blocked, must renew

    rows = User.where(id: @user.id)
               .where("conversions_count < ?", FREE_LIMIT)
               .update_all("conversions_count = conversions_count + 1")

    claimed = rows == 1
    @user.reload if claimed
    claimed
  end

  # Give one unit back (e.g. the conversion ultimately failed). Never drops the
  # counter below zero, and is safe to call at most once per claimed unit.
  def refund!
    return false if @user.nil? || unlimited?

    rows = User.where(id: @user.id)
               .where("conversions_count > 0")
               .update_all("conversions_count = conversions_count - 1")

    refunded = rows == 1
    @user.reload if refunded
    refunded
  end

  # Backwards-compatible alias for the old non-atomic API.
  alias_method :increment!, :claim!

  def status_message
    if @user.nil?
      "Please sign up to download your files."
    elsif unlimited?
      "Unlimited conversions on Pro plan."
    elsif @user.pro? && !@user.active?
      "Your Pro subscription is inactive. Please update your billing."
    elsif limit_reached?
      "You have reached your free limit. Upgrade to Pro."
    else
      "#{remaining} free conversions remaining."
    end
  end
end
