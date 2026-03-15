require "test_helper"

# Plain Ruby class for testing interceptors without ActiveRecord internals interfering
class Calculator
  def add(a, b)
    a + b
  end

  def subtract(a, b)
    a - b
  end

  def multiply(a, b)
    a * b
  end

  def divide(a, b)
    a.to_f / b
  end

  def self.pi
    3.14159
  end

  def self.euler
    2.71828
  end
end

class InterceptorIntegrationTest < ActiveSupport::TestCase
  setup do
    Sinaliza::InterceptorRegistry.reset!
  end

  test "intercepting an instance method records an event" do
    Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "add",
      event_name: "calculator.add_called"
    )

    calc = Calculator.new

    assert_difference "Sinaliza::Event.count", 1 do
      calc.add(1, 2)
    end

    event = Sinaliza::Event.last
    assert_equal "calculator.add_called", event.name
    assert_equal "interceptor", event.source
  end

  test "deactivated interceptor does not record events" do
    interceptor = Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "subtract",
      event_name: "calculator.subtract_called"
    )

    interceptor.deactivate!
    calc = Calculator.new

    assert_no_difference "Sinaliza::Event.count" do
      calc.subtract(5, 3)
    end
  end

  test "reactivated interceptor records events again" do
    interceptor = Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "subtract",
      event_name: "calculator.subtract_called"
    )

    interceptor.deactivate!
    interceptor.activate!

    calc = Calculator.new

    assert_difference "Sinaliza::Event.count", 1 do
      calc.subtract(5, 3)
    end
  end

  test "captures arguments when capture_args is true" do
    Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "add",
      event_name: "calculator.add_called",
      capture_args: true
    )

    calc = Calculator.new
    calc.add(10, 20)

    event = Sinaliza::Event.last
    assert_equal [ "10", "20" ], event.metadata["args"]
  end

  test "captures return value when capture_return is true" do
    Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "add",
      event_name: "calculator.add_called",
      capture_return: true
    )

    calc = Calculator.new
    result = calc.add(10, 20)

    assert_equal 30, result
    event = Sinaliza::Event.last
    assert_equal "30", event.metadata["return"]
  end

  test "captures execution time when capture_execution_time is true" do
    Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "add",
      event_name: "calculator.add_called",
      capture_execution_time: true
    )

    calc = Calculator.new
    calc.add(10, 20)

    event = Sinaliza::Event.last
    assert event.metadata["execution_time_ms"].is_a?(Numeric)
    assert event.metadata["execution_time_ms"] >= 0
  end

  test "intercepting a class method" do
    Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "pi",
      event_name: "calculator.pi_called",
      method_type: "class"
    )

    assert_difference "Sinaliza::Event.count", 1 do
      Calculator.pi
    end

    event = Sinaliza::Event.last
    assert_equal "calculator.pi_called", event.name
    assert_equal "interceptor", event.source
  end

  test "intercepted method returns original value" do
    Sinaliza::Interceptor.create!(
      target_class: "Calculator",
      method_name: "multiply",
      event_name: "calculator.multiply_called"
    )

    calc = Calculator.new
    assert_equal 15, calc.multiply(3, 5)
  end

  test "nonexistent class does not raise on apply" do
    assert_nothing_raised do
      Sinaliza::Interceptor.create!(
        target_class: "NonexistentClass",
        method_name: "foo",
        event_name: "test"
      )
    end
  end

  test "Sinaliza.intercept creates and applies an interceptor" do
    interceptor = Sinaliza.intercept("Calculator", :divide, event_name: "calculator.divide_called")

    assert interceptor.persisted?
    assert interceptor.active?
    assert Sinaliza::InterceptorRegistry.applied?(interceptor)

    calc = Calculator.new

    assert_difference "Sinaliza::Event.count", 1 do
      calc.divide(10, 3)
    end
  end

  test "registry apply_all! loads and applies all interceptors" do
    Sinaliza::Interceptor.create!(target_class: "Calculator", method_name: "euler", event_name: "calculator.euler_called", method_type: "class")
    Sinaliza::InterceptorRegistry.reset!

    Sinaliza::InterceptorRegistry.apply_all!

    assert_difference "Sinaliza::Event.count", 1 do
      Calculator.euler
    end
  end

  test "captures kwargs when capture_args is true" do
    klass = Class.new do
      def greet(name:, greeting: "Hello")
        "#{greeting}, #{name}!"
      end
    end
    Object.const_set(:Greeter, klass) unless defined?(::Greeter)

    Sinaliza::Interceptor.create!(
      target_class: "Greeter",
      method_name: "greet",
      event_name: "greeter.greet_called",
      capture_args: true
    )

    obj = Greeter.new
    obj.greet(name: "Alice", greeting: "Hi")

    event = Sinaliza::Event.last
    assert_equal({ "name" => "\"Alice\"", "greeting" => "\"Hi\"" }, event.metadata["kwargs"])
  end
end
