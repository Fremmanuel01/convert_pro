class ConversionLimiter
  FREE_LIMIT = 5

  def initialize(user)
    @user = user
  end

  def can_convert?
    return true if @user.nil?
    return true if @user.pro? && @user.active?
    @user.free? && !limit_reached?
  end

  def limit_reached?
    return false if @user.nil?
    @user.conversions_count >= FREE_LIMIT
  end

  def remaining
    return :unlimited if @user.nil?
    return :unlimited if @user.pro? && @user.active?
    
    left = FREE_LIMIT - @user.conversions_count
    left > 0 ? left : 0
  end

  def increment!
    return false if @user.nil?
    return false unless can_convert?

    @user.increment!(:conversions_count)
    true
  end

  def status_message
    if @user.nil?
      "Please sign up to download your files."
    elsif @user.pro? && @user.active?
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
