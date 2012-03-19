require 'test/unit'
require File.expand_path("../../lib/django_signal", __FILE__)

class DjangoSignalTest < Test::Unit::TestCase
  def setup
    @s = DjangoSignal.new
  end

  def produce_dead_ref
    dead_ref = WeakRef.new(Object.new)
    GC.start # to force gc and make dead_ref dead.

    assert !dead_ref.weakref_alive?, "WeakRef is alive! Can't produce them!"
    dead_ref
  end

  def test_simple
    called = false
    @s.connect(lambda {|opts| called = true})
    @s.send(nil)

    assert called
  end

  def test_filter_sender
    a_called = false
    b_called = false
    nil_called = false
    @s.connect(lambda {|opts| nil_called = true})
    @s.connect(lambda {|opts| a_called = true}, :a)
    @s.connect(lambda {|opts| b_called = true}, :b)

    @s.send(:a)

    assert a_called
    assert !b_called
    assert nil_called
  end

  def test_ignore_dead_refs
    @s.connect(self.produce_dead_ref())

    assert_equal({}, @s.send(nil))
  end

  def test_send_propagets_exception
    assert_raise Exception do
      @s.connect(lambda {|opts| raise Exception})

      @s.send(nil)
    end
  end

  def test_send_robust_captures_exceptions
    ex = Exception.new
    r = lambda{|a| raise ex}

    @s.connect(r)

    assert_equal({r => ex}, @s.send_robust(nil))
  end

  def test_ignore_dead_refs_on_robust
    @s.connect(self.produce_dead_ref())

    assert_equal({}, @s.send_robust(nil))
  end

  def test_cannot_reregister_same_object
    call_count = 0
    l = lambda {|opts| call_count += 1}
    @s.connect(l)
    @s.connect(l)

    @s.send(nil)

    assert_equal 1, call_count
  end

  def test_can_re_register_different_object_even_if_they_seem_alike
    # Particularly on re-imports or reloads.
    call_count = 0
    @s.connect(lambda {|opts| call_count += 1})
    @s.connect(lambda {|opts| call_count += 1})

    @s.send(nil)

    assert_equal 2, call_count
  end

  def test_can_not_re_register_with_same_dispatch_uid
    call_count = 0
    @s.connect(lambda {|opts| call_count += 1}, nil, :adder)
    @s.connect(lambda {|opts| call_count += 1}, nil, :adder)

    @s.send(nil)

    assert_equal 1, call_count
  end
end
