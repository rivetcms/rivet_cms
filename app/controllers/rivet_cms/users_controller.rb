module RivetCms
  # User management for built-in authentication mode. Hidden and denied under
  # host auth. CE has no roles, so this is add / edit / deactivate only; every
  # user can do everything. Users are deactivated, never deleted, since audit
  # events and content attribution reference them.
  #
  # The authorize! :users gates below pass for everyone under CE's allow-all
  # policy; they are the seam through which Pro restricts user management to
  # its own roles.
  class UsersController < ApplicationController
    before_action :ensure_builtin_mode
    before_action -> { authorize! :read, :users }, only: [ :index ]
    before_action -> { authorize! :write, :users }, except: [ :index ]
    before_action :set_user, except: [ :index, :create ]
    before_action -> { authorize! :write, :users, record: @user }, except: [ :index, :create ]

    def index
      render inertia: "Users/Index", props: {
        users: users.order(:created_at).map { |user| user_props(user) },
        invite_link: flash[:invite_link]
      }
    end

    def create
      user = users.new(user_params)

      if user.save
        audit "user.created", user
        flash[:invite_link] = invitation_url(user.generate_token_for(:password_setup))
        redirect_to users_path, notice: "#{user.name} was added. Share the sign-in link below; it is shown only once."
      else
        redirect_to users_path, inertia: { errors: user.errors }
      end
    end

    def update
      if @user.update(user_params)
        audit "user.updated", @user
        redirect_to users_path, notice: "#{@user.name} was updated"
      else
        redirect_to users_path, inertia: { errors: @user.errors }
      end
    end

    def deactivate
      if @user == Current.user
        return redirect_to users_path, alert: "You cannot deactivate your own account"
      end

      locked_out = User.transaction do
        # Lock every user who can actually sign in (active with a password) so
        # two concurrent deactivations serialize instead of both seeing "one
        # other can still sign in" and leaving nobody who can. Pending
        # invitees have no password and do not count. (No-op on SQLite,
        # honored on Postgres/MySQL.)
        signin_ids = users.active.where.not(password_digest: nil).order(:id).lock.pluck(:id)
        next true if signin_ids.include?(@user.id) && (signin_ids - [ @user.id ]).empty?

        @user.update!(active: false)
        false
      end

      if locked_out
        return redirect_to users_path, alert: "At least one active user must remain, or no one could sign in"
      end

      audit "user.deactivated", @user
      redirect_to users_path, notice: "#{@user.name} was deactivated and can no longer sign in"
    end

    def reactivate
      @user.update!(active: true)
      audit "user.reactivated", @user
      redirect_to users_path, notice: "#{@user.name} was reactivated"
    end

    def reset_link
      flash[:invite_link] = invitation_url(@user.generate_token_for(:password_setup))
      redirect_to users_path, notice: "New sign-in link for #{@user.name}; it is shown only once."
    end

    private

    def ensure_builtin_mode
      head :not_found unless RivetCms.builtin_auth?
    end

    def users
      User.where(organization: Current.organization)
    end

    def set_user
      @user = users.find(params[:id])
    end

    def user_params
      params.permit(:name, :email)
    end

    def user_props(user)
      {
        id: user.prefix_id,
        name: user.name,
        email: user.email,
        status: user.status,
        yourself: user == Current.user,
        created_at: user.created_at.iso8601,
        paths: {
          update: user_path(user),
          deactivate: deactivate_user_path(user),
          reactivate: reactivate_user_path(user),
          reset_link: reset_link_user_path(user)
        }
      }
    end
  end
end
