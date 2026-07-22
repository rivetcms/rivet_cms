module RivetCms
  class ApiTokensController < ApplicationController
    include InertiaProps

    def index
      render inertia: "ApiTokens/Index", props: {
        tokens: api_tokens.recent.map { |token| api_token_json(token) },
        new_token: flash[:new_token]
      }
    end

    def create
      scope = params[:scope].presence_in(%w[published preview]) || "published"
      token = ApiToken.generate!(name: params[:name].to_s, scope: scope)
      flash[:new_token] = token.plaintext
      redirect_to api_tokens_path, notice: "API token created — copy it now; it won't be shown again."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to api_tokens_path, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      api_tokens.find(params[:id]).destroy
      redirect_to api_tokens_path, notice: "API token revoked"
    end

    private

    def api_tokens
      Current.organization.api_tokens
    end
  end
end
