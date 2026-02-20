class TrackedController < ApplicationController
  include Sinaliza::Traceable

  track_event "page.viewed", only: :index
  track_event "item.shown", only: :show, metadata: ->(controller = self) { { id: params[:id] } }

  def index
    head :ok
  end

  def show
    head :ok
  end

  def create
    record_event("item.created", metadata: { custom: true })
    head :ok
  end

  private

  def current_user
    @current_user ||= User.find_by(id: request.headers["X-User-Id"])
  end
end
