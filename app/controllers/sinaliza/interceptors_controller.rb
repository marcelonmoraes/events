module Sinaliza
  class InterceptorsController < ApplicationController
    before_action :set_interceptor, only: [ :edit, :update, :destroy, :toggle ]

    def index
      @interceptors = Interceptor.order(created_at: :desc)
    end

    def new
      @interceptor = Interceptor.new
    end

    def create
      @interceptor = Interceptor.new(interceptor_params)

      if @interceptor.save
        redirect_to interceptors_path, notice: "Interceptor created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @interceptor.update(interceptor_params)
        redirect_to interceptors_path, notice: "Interceptor updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @interceptor.destroy
      redirect_to interceptors_path, notice: "Interceptor removed."
    end

    def toggle
      if @interceptor.active?
        @interceptor.deactivate!
      else
        @interceptor.activate!
      end

      redirect_to interceptors_path
    end

    private

    def set_interceptor
      @interceptor = Interceptor.find(params[:id])
    end

    def interceptor_params
      params.require(:interceptor).permit(
        :target_class, :method_name, :method_type, :event_name,
        :capture_args, :capture_return, :capture_execution_time
      )
    end
  end
end
