module RivetCms
  class MediaAssetsController < ApplicationController
    include InertiaProps

    before_action -> { authorize! :read, :media }, only: [ :index ]
    before_action -> { authorize! :delete, :media }, only: [ :destroy ]
    before_action -> { authorize! :write, :media }, except: [ :index, :destroy ]

    def index
      scope = media_assets.recent
      scope = scope.search(params[:q]) if params[:q].present?
      scope = scope.where(kind: params[:kind]) if MediaAsset.kinds.key?(params[:kind])
      page = scope.page(params[:page]).per(48)
      assets = permitted(page, :read, :media).map { |asset| media_asset_json(asset) }

      respond_to do |format|
        format.json { render json: assets }
        format.html do
          render inertia: "Media/Index", props: {
            assets: assets,
            q: params[:q].presence,
            kind: params[:kind].presence,
            kinds: media_assets.distinct.order(:kind).pluck(:kind),
            pagination: { page: page.current_page, total_pages: page.total_pages }
          }
        end
      end
    end

    def create
      unless params[:file].respond_to?(:tempfile)
        return render json: { errors: [ "file is required" ] }, status: :unprocessable_entity
      end

      asset = MediaAsset.new(file: params[:file])

      if asset.save
        audit "media.uploaded", asset
        render json: media_asset_json(asset), status: :created
      else
        render json: { errors: asset.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      asset = media_assets.find(params[:id])
      authorize! :write, :media, record: asset
      if asset.update(params.permit(:title, :alt, :description))
        audit "media.updated", asset
        render json: media_asset_json(asset)
      else
        render json: { errors: asset.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      asset = media_assets.find(params[:id])
      authorize! :delete, :media, record: asset
      if asset.embedded_in_content?
        return redirect_to media_assets_path, alert: "Media is embedded in content and cannot be deleted"
      end

      asset.destroy
      audit "media.deleted", asset
      redirect_to media_assets_path, notice: "Media deleted"
    rescue ActiveRecord::InvalidForeignKey
      redirect_to media_assets_path, alert: "Media is in use by content and cannot be deleted"
    end

    private

    def media_assets
      Current.organization.media_assets
    end
  end
end
