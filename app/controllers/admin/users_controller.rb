module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @user = User.find(params[:id])
      @conversions = @user.conversions.order(created_at: :desc).limit(20)
    end

    def toggle_admin
      @user = User.find(params[:id])
      @user.update!(admin: !@user.admin?)
      redirect_to admin_user_path(@user), notice: "Admin status updated."
    end
  end
end
