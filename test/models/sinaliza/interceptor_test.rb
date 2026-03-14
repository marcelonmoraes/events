require "test_helper"

module Sinaliza
  class InterceptorTest < ActiveSupport::TestCase
    setup do
      InterceptorRegistry.reset!
    end

    test "requires target_class" do
      interceptor = Interceptor.new(target_class: nil, method_name: "foo", event_name: "test")
      assert_not interceptor.valid?
      assert_includes interceptor.errors[:target_class], "can't be blank"
    end

    test "requires method_name" do
      interceptor = Interceptor.new(target_class: "User", method_name: nil, event_name: "test")
      assert_not interceptor.valid?
      assert_includes interceptor.errors[:method_name], "can't be blank"
    end

    test "requires event_name" do
      interceptor = Interceptor.new(target_class: "User", method_name: "foo", event_name: nil)
      assert_not interceptor.valid?
      assert_includes interceptor.errors[:event_name], "can't be blank"
    end

    test "validates method_type inclusion" do
      interceptor = Interceptor.new(target_class: "User", method_name: "foo", event_name: "test", method_type: "invalid")
      assert_not interceptor.valid?
      assert_includes interceptor.errors[:method_type], "is not included in the list"
    end

    test "validates uniqueness of target_class, method_name, and method_type" do
      Interceptor.create!(target_class: "User", method_name: "foo", event_name: "test.event")

      duplicate = Interceptor.new(target_class: "User", method_name: "foo", event_name: "other.event")
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:target_class], "has already been taken"
    end

    test "allows same method_name with different method_type" do
      Interceptor.create!(target_class: "User", method_name: "foo", event_name: "test.instance", method_type: "instance")
      class_interceptor = Interceptor.new(target_class: "User", method_name: "foo", event_name: "test.class", method_type: "class")

      assert class_interceptor.valid?
    end

    test "defaults to instance method_type" do
      interceptor = Interceptor.new
      assert_equal "instance", interceptor.method_type
    end

    test "defaults to active" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "foo", event_name: "test")
      assert interceptor.active?
    end

    test "active scope" do
      Interceptor.create!(target_class: "User", method_name: "foo", event_name: "test", active: true)
      Interceptor.create!(target_class: "User", method_name: "bar", event_name: "test2", active: false)

      assert_equal 1, Interceptor.active.count
    end

    test "inactive scope" do
      Interceptor.create!(target_class: "User", method_name: "foo", event_name: "test", active: true)
      Interceptor.create!(target_class: "User", method_name: "bar", event_name: "test2", active: false)

      assert_equal 1, Interceptor.inactive.count
    end

    test "by_target_class scope" do
      Interceptor.create!(target_class: "User", method_name: "foo", event_name: "test")
      Interceptor.create!(target_class: "Post", method_name: "bar", event_name: "test2")

      assert_equal 1, Interceptor.by_target_class("User").count
    end

    test "activate! sets active to true and applies interceptor" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test", active: false)
      InterceptorRegistry.reset!

      interceptor.activate!

      assert interceptor.active?
      assert InterceptorRegistry.applied?(interceptor)
    end

    test "deactivate! sets active to false" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test", active: true)

      interceptor.deactivate!

      assert_not interceptor.active?
    end

    test "key for instance method" do
      interceptor = Interceptor.new(target_class: "User", method_name: "foo", method_type: "instance")
      assert_equal "User#foo", interceptor.key
    end

    test "key for class method" do
      interceptor = Interceptor.new(target_class: "User", method_name: "foo", method_type: "class")
      assert_equal "User.foo", interceptor.key
    end

    test "applies interceptor on create" do
      interceptor = Interceptor.create!(target_class: "User", method_name: "name", event_name: "test")

      assert InterceptorRegistry.applied?(interceptor)
    end
  end
end
