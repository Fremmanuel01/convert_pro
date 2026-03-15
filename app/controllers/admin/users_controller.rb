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

    def destroy
      @user = User.find(params[:id])
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete your own account."
      else
        email = @user.email
        @user.destroy!
        redirect_to admin_users_path, notice: "User #{email} deleted."
      end
    end
  end
end
