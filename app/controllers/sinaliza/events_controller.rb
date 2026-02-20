module Sinaliza
  class EventsController < ApplicationController
    PER_PAGE = 50

    def index
      @events = Event.roots.reverse_chronological

      apply_filters
      apply_cursor_pagination

      @filter_names = Event.distinct.pluck(:name).sort
      @filter_sources = Event.distinct.pluck(:source).sort
      @filter_actor_types = Event.where.not(actor_type: nil).distinct.pluck(:actor_type).sort
    end

    def show
      @event = Event.find(params[:id])
      @children = @event.children.reverse_chronological
    end

    private

    def apply_filters
      @events = @events.by_name(params[:name]) if params[:name].present?
      @events = @events.by_source(params[:source]) if params[:source].present?
      @events = @events.by_actor_type(params[:actor_type]) if params[:actor_type].present?
      @events = @events.search(params[:q]) if params[:q].present?
      @events = @events.since(Date.parse(params[:since])) if params[:since].present?
      @events = @events.before(Date.parse(params[:before]).end_of_day) if params[:before].present?
    end

    def apply_cursor_pagination
      @events = @events.where("sinaliza_events.id < ?", params[:before_id].to_i) if params[:before_id].present?
      @events = @events.limit(PER_PAGE + 1).to_a

      @has_next_page = @events.size > PER_PAGE
      @events = @events.first(PER_PAGE)
      @next_cursor = @events.last&.id if @has_next_page
    end
  end
end
