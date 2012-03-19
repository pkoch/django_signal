require 'test/unit'
require File.expand_path("../../lib/django_signal", __FILE__)

class DjangoSignalTest < Test::Unit::TestCase
  def setup
    @s = DjangoSignal.new
  end

  def produce_fragile_ref
    WeakRef.new(lambda{|*a| 0})
  end

  def test_simple
    given_args = nil
    @s.connect(lambda {|*a| given_args = a})
    @s.send(:sender, :random_arg)

    assert_equal(
      [@s, :sender, :random_arg],
      given_args,
    )
  end

  def test_filter_sender
    a_called = false
    b_called = false
    nil_called = false
    @s.connect(lambda {|*a| nil_called = true})
    @s.connect(lambda {|*a| a_called = true}, :a)
    @s.connect(lambda {|*a| b_called = true}, :b)

    @s.send(:a)

    assert a_called
    assert !b_called
    assert nil_called
  end

  def test_ignore_dead_refs
    @s.connect(self.produce_fragile_ref())

    GC.start

    assert_equal({}, @s.send(nil))
  end

  def test_send_propagets_exception
    assert_raise Exception do
      @s.connect(lambda {|*a| raise Exception})

      @s.send(nil)
    end
  end

  def test_send_robust_captures_exceptions
    ex = Exception.new
    r = lambda{|*a| raise ex}

    @s.connect(r)

    assert_equal({r => ex}, @s.send_robust(nil))
  end

  def test_ignore_dead_refs_on_robust
    @s.connect(self.produce_fragile_ref())

    GC.start

    assert_equal({}, @s.send_robust(nil))
  end

  def test_cannot_reregister_same_object
    call_count = 0
    l = lambda {|*a| call_count += 1}
    @s.connect(l)
    @s.connect(l)

    @s.send(nil)

    assert_equal 1, call_count
  end

  def test_can_re_register_different_object_even_if_they_seem_alike
    # Particularly on re-imports or reloads.
    call_count = 0
    @s.connect(lambda {|*a| call_count += 1})
    @s.connect(lambda {|*a| call_count += 1})

    @s.send(nil)

    assert_equal 2, call_count
  end

  def test_can_not_re_register_with_same_dispatch_uid
    call_count = 0
    @s.connect(lambda {|*a| call_count += 1}, nil, :adder)
    @s.connect(lambda {|*a| call_count += 1}, nil, :adder)

    @s.send(nil)

    assert_equal 1, call_count
  end

  def test_force_receiver_to_be_a_callable
    assert_raise DjangoSignal::InvalidReceiver do
      @s.connect(Object.new)
    end
  end

  def test_force_receiver_arity
    assert_raise DjangoSignal::InvalidReceiver do
      @s.connect(lambda { 0 })
    end

    assert_raise DjangoSignal::InvalidReceiver do
      @s.connect(lambda { |signal| 0 })
    end

    @s.connect(lambda { |signal, sender| 0 })
    @s.connect(lambda { |*a| 0 })
  end
end
