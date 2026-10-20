# First-run screen: creates the single user of the app. Closed once a user exists.
class SetupsController < ApplicationController
  allow_unauthenticated_access
  before_action :ensure_no_user

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[ email_address password password_confirmation ]))

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Conta criada. Bem-vindo ao WorkMachine!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def ensure_no_user
      redirect_to new_session_path if User.exists?
    end
end
