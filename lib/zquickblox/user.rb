require_relative "user/create_user_request"
require_relative "user/find_user_request"
require_relative "user/delete_user_request"

module ZQuickblox
  module User
    class << self
      def create(params)
        user = User.new(params)
        params = user.build_params
        request = ZQuickblox::User::CreateUserRequest.new(params)
        run_request(request)
        user = User.new(ZQuickblox::Util.symbolize_keys(request.response_body["user"]))
        return user
      end

      def find(login)
        request = ZQuickblox::User::FindUserRequest.new(login)
        run_request(request)
        return nil if request.response.status == 404
        user = User.new(ZQuickblox::Util.symbolize_keys(request.response_body["user"]))
        return user
      end

      def delete(login, password, id)
        request = ZQuickblox::User::DeleteUserRequest.new(id)
        run_request(request, login, password)
        return nil if request.response.status != 200
        return {}
      end

      def run_request(request, login=nil, password=nil)
        session = ZQuickblox::Session.create(login, password)
        request.header("QB-Token", session.token)
        request.execute
      end
    end

    class User
      attr_accessor :id, :login, :password, :email, :blob_id, :external_user_id
      attr_accessor :facebook_id, :twitter_id, :full_name, :phone, :website

      def initialize(params)
        @id               = params[:id]
        @login            = params[:login]
        @password         = params[:password]
        @email            = params[:email]
        @blob_id          = params[:blob_id]
        @external_user_id = params[:external_user_id]
        @facebook_id      = params[:facebook_id]
        @twitter_id       = params[:twitter_id]
        @full_name        = params[:full_name]
        @phone            = params[:phone]
        @website          = params[:website]
      end

      def build_params
        @params = {
          "user[login]":            @login,
          "user[password]":         @password,
          "user[email]":            @email,
          "user[blob_id]":          @blob_id,
          "user[external_user_id]": @external_user_id,
          "user[facebook_id]":      @facebook_id,
          "user[twitter_id]":       @twitter_id,
          "user[full_name]":        @full_name,
          "user[phone]":            @phone,
          "user[website]":          @website
        }
      end
    end
  end
end
