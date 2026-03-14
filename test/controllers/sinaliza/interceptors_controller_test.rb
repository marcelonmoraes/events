require "test_helper"

module Sinaliza
  class InterceptorsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
      InterceptorRegistry.reset!
    end

    test "index returns success" do
      get interceptors_url
      assert_response :success
    end

    test "index lists interceptors" do
      Interceptor.create!(target_class: "User", method_name: "name", event_name: "user.name_called")
      Interceptor.create!(target_class: "Post", method_name: "title", event_name: "post.title_called")

      get interceptors_url
      assert_response :success
      assert_select "table.sinaliza-table tbody tr", 2
    end

    test "new returns success" do
      get new_interceptor_url
      assert_response :success
    end

    test "create with valid params" do
      assert_difference "Interceptor.count", 1 do
        post interceptors_url, params: { interceptor: {
          target_class: "User",
          method_name: "name",
          event_name: "user.name_called",
          method_type: "instance"
        } }
      end

      assert_redirected_to interceptors_path
    end

    test "create with invalid params renders new" do
      assert_no_difference "Interceptor.count" do
        post interceptors_url, params: { interceptor: {
          target_class: "",
          method_name: "",
          event_name: ""
        } }
      end

      assert_response :unprocessable_entity
    end

    test "edit returns success" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test")

      get edit_interceptor_url(interceptor)
      assert_response :success
    end

    test "update with valid params" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test")

      patch interceptor_url(interceptor), params: { interceptor: { event_name: "user.name_updated" } }
      assert_redirected_to interceptors_path

      interceptor.reload
      assert_equal "user.name_updated", interceptor.event_name
    end

    test "update with invalid params renders edit" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test")

      patch interceptor_url(interceptor), params: { interceptor: { event_name: "" } }
      assert_response :unprocessable_entity
    end

    test "destroy removes interceptor" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test")

      assert_difference "Interceptor.count", -1 do
        delete interceptor_url(interceptor)
      end

      assert_redirected_to interceptors_path
    end

    test "toggle deactivates active interceptor" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test", active: true)

      patch toggle_interceptor_url(interceptor)
      assert_redirected_to interceptors_path

      interceptor.reload
      assert_not interceptor.active?
    end

    test "toggle activates inactive interceptor" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test", active: false)

      patch toggle_interceptor_url(interceptor)
      assert_redirected_to interceptors_path

      interceptor.reload
      assert interceptor.active?
    end

    test "index shows active status" do
      Interceptor.create!(target_class: "User", method_name: "name", event_name: "test", active: true)

      get interceptors_url
      assert_select ".sinaliza-status--active", "Active"
    end

    test "index shows inactive status" do
      Interceptor.create!(target_class: "User", method_name: "name", event_name: "test", active: false)

      get interceptors_url
      assert_select ".sinaliza-status--inactive", "Inactive"
    end

    private

    def interceptors_url
      sinaliza.interceptors_url
    end

    def interceptor_url(interceptor)
      sinaliza.interceptor_url(interceptor)
    end

    def new_interceptor_url
      sinaliza.new_interceptor_url
    end

    def edit_interceptor_url(interceptor)
      sinaliza.edit_interceptor_url(interceptor)
    end

    def toggle_interceptor_url(interceptor)
      sinaliza.toggle_interceptor_url(interceptor)
    end
  end
end
