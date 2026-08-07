module RivetCms
  class ApiTokensController < ApplicationController
    include InertiaProps

    before_action -> { authorize! :read, :api }, only: [ :index ]
    before_action -> { authorize! :write, :api }, except: [ :index, :destroy ]
    before_action -> { authorize! :delete, :api }, only: [ :destroy ]
    # Tokens read content through the delivery API, so minting one requires
    # content read; otherwise a content-denied user could escalate via a token.
    before_action -> { authorize! :read, :content }, only: [ :create ]

    def index
      render inertia: "ApiTokens/Index", props: {
        tokens: permitted(api_tokens.recent, :read, :api).map { |token| api_token_json(token) },
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
      token = api_tokens.find(params[:id])
      authorize! :delete, :api, record: token
      token.destroy
      redirect_to api_tokens_path, notice: "API token revoked"
    end

    private

    def api_tokens
      Current.organization.api_tokens
    end
  end
end
