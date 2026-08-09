module RivetCms
  class SessionsController < AuthController
    LOGIN_ATTEMPT_LIMIT = 10
    LOGIN_ATTEMPT_WINDOW = 5.minutes

    # Memoized on the class, computed on first use so BCrypt is referenced at
    # request time (after bcrypt is required), never at load time
    def self.dummy_digest
      @dummy_digest ||= BCrypt::Password.create("rivet-cms-timing-equalizer").to_s
    end

    def new
      return redirect_to root_path if builtin_session_user
      return redirect_to setup_path if users.none?

      render inertia: "Auth/Login", props: { submit_path: login_path }
    end

    def create
      # Reserve an attempt atomically BEFORE authenticating, so a parallel
      # burst cannot slip every request through BCrypt before any counter
      # reaches the limit. The increment is the reservation.
      unless reserve_attempt
        return redirect_to login_path,
                           inertia: { errors: { base: [ "Too many attempts. Wait a few minutes and try again" ] } }
      end

      user = users.active.find_by(email: submitted_email)
      if user&.can_sign_in? && user.authenticate(params[:password].to_s)
        release_reservation_on_success
        sign_in(user)
        redirect_to root_path
      else
        equalize_timing unless user&.can_sign_in?
        # Failure keeps its reservation; that is the point of the counters
        redirect_to login_path, inertia: { errors: { base: [ "That email and password combination does not work" ] } }
      end
    end

    def destroy
      reset_session
      redirect_to login_path, status: :see_other
    end

    private

    # A BCrypt comparison runs on every login attempt, so an attacker cannot
    # tell known emails (expensive compare) from unknown ones (fast return)
    # by timing; only its cost matters, never its content.
    def equalize_timing
      BCrypt::Password.new(self.class.dummy_digest).is_password?(params[:password].to_s)
    end

    # Two independent counters guard login: one per source IP, one per target
    # account (scoped by organization, so the same email in another tenant is
    # a separate counter). See reserve_attempt for the ordering that keeps the
    # two from corrupting each other, and release_reservation_on_success for
    # what a successful login does and does not clear.
    #
    # This needs a shared, incrementing cache (Redis, Memcached) to bind
    # multiple workers; on a per-process MemoryStore it is per-worker, and on
    # the NullStore it does nothing. It is a floor, not a replacement for
    # rack-attack or a WAF at the edge.
    def submitted_email
      params[:email].to_s.strip.downcase
    end

    def ip_throttle_key
      "rivet_cms:login_attempts:ip:#{request.remote_ip}"
    end

    def account_throttle_key(email = submitted_email)
      "rivet_cms:login_attempts:account:#{Current.organization&.id}:#{email}"
    end

    # Reserve one IP attempt, then one account attempt, checking each before
    # reserving the next. Returns false (throttled) without ever touching the
    # account counter once the IP is over limit, so a blocked IP cannot lock
    # arbitrary accounts. If the account is over limit, the IP reservation
    # this request just made is released, so an already-locked account does
    # not drain the shared IP budget.
    def reserve_attempt
      return false if over_limit?(bump(ip_throttle_key))

      if over_limit?(bump(account_throttle_key))
        unbump(ip_throttle_key)
        return false
      end
      true
    end

    def over_limit?(count)
      # nil (NullStore) means throttling is disabled, never over limit
      count && count > LOGIN_ATTEMPT_LIMIT
    end

    # A success proves ownership of this account, so clear its counter; but it
    # only releases this request's own IP reservation, never the whole IP
    # history, so one account's success cannot erase IP-wide spray protection.
    def release_reservation_on_success
      unbump(ip_throttle_key)
      Rails.cache.delete(account_throttle_key)
    end

    def bump(key)
      # increment is atomic on stores that support it; it seeds the key on a
      # real store, and returns nil on the NullStore (throttling disabled)
      Rails.cache.increment(key, 1, expires_in: LOGIN_ATTEMPT_WINDOW)
    end

    # Release a reservation only if it is still live. A bare decrement on an
    # expired key recreates it as a non-expiring -1, a permanent counter that
    # later increments accumulate on and can eventually lock the IP forever.
    # The exist? check skips that; expires_in bounds the entry anyway if the
    # key expires in the race between the check and the decrement.
    def unbump(key)
      return unless Rails.cache.exist?(key)

      Rails.cache.decrement(key, 1, expires_in: LOGIN_ATTEMPT_WINDOW)
    end
  end
end
