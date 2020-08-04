class TokenController < ApplicationController
  require 'securerandom'
  require 'redis'

  def initialize
    $redis = Redis.new(host: "localhost")
  end

  def generate_token
    token = SecureRandom.uuid
    $redis.set("token:#{token}", token)
    $redis.expire("token:#{token}", 300)
    render json: {token: token}, status: :ok
  end

  def assign_token
    live_token_keys = $redis.keys("token:*")
    live_tokens = live_token_pair.map{|key| key.to_s.split(":")[1]}
    user = @user
    user_token_keys = $redis.keys("*:user")
    user_tokens = user_token_keys.map{|key| key.to_s.split(":")[0]}
    unassigned_tokens = live_tokens - user_tokens
    if unassigned_tokens.present?
      token = unassigned_tokens.first
      $redis.set("#{token}:user", user)
      $redis.expire("#{token}:user", 60)
      render json: {token: token}, status: :ok
    else
      raise ActionController::RoutingError.new('Not Found')
    end

  end

  def unblock_token
    user = @user
    user_token = $redis.keys("*:user")
    token = user_token.split(":")[0]
    $redis.del("#{token}:#{user}")
  end

  def delete_token
    user = @user
    user_token = $redis.keys("*:user")
    token = user_token.split(":")[0]
    $redis.del("#{token}:#{user}")
    $redis.del("#{token}:#{token}")
  end

  def refresh_token
    user = @user
    user_token = $redis.keys("*:user")
    token = user_token.split(":")[0]
    $redis.expire("#{token}:#{user}", 60)
  end

  private

	def set_user
    	@user = params[:user]
  	end
end
