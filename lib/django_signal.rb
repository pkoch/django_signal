require 'thread'
require 'weakref'

#
# DjangoSignal
# See https://docs.djangoproject.com/en/dev/topics/signals/#defining-and-sending-signals
#
# Obviously, I didn't wire this signals to ActiveRecord.
#
# Also, I took the liberty to make some adaptations. Namely:
# * No explicit weakref stuff. Want a weakref? Build if yourself.
#   Invalid refs are handled gracefuly.
# * No providing_args, since they had no functional relevance.
#
class DjangoSignal
  #
  # Create a new signal.
  #
  def initialize
    @receivers = {}
    @lock = Mutex.new
  end

  #
  # Connect receiver to sender for signal.
  # 
  # +receiver+:: A callable which is to receive signals.
  #             If dispatch_uid is given, the receiver will not be added if
  #             another receiver already exists with that dispatch_uid.
  # +sender+:: The sender to which the receiver should respond or nil to
  #            receive events from any sender.
  # +dispatch_uid+:: An identifier used to uniquely identify a particular
  #                  instance of a receiver. This will usually be a symbol,
  #                  though it may be anything with an object_id.
  #
  def connect(receiver, sender=nil, dispatch_uid=nil)
    lookup_key = make_key(receiver, sender, dispatch_uid)

    @lock.synchronize {
      @receivers[lookup_key] ||= receiver
    }
  end

  #
  # Disconnect receiver from sender for signal.
  #
  # If weak references are used, disconnect need not be called. The receiver
  # will be remove from dispatch automatically.
  # 
  # +receiver+:: The registered receiver to disconnect. May be nil if
  #              dispatch_uid is specified.
  # +sender+:: The registered sender to disconnect
  # +dispatch_uid+:: the unique identifier of the receiver to disconnect
  #
  def disconnect(receiver, sender=nil, dispatch_uid=nil)
    lookup_key = make_key(receiver, sender, dispatch_uid)

    @lock.synchronize {
      @receivers.delete(lookup_key)
    }
  end

  #
  # Send signal from sender to all connected receivers.
  # 
  # If any receiver raises an error, the error propagates back through send,
  # terminating the dispatch loop, so it is quite possible to not have all
  # receivers called if a raises an error.
  # 
  # +sender+:: The sender of the signal. Either a specific object or nil.
  # +args+:: Args which will be passed to receivers.
  # 
  # Returns a hash +{receiver => response, ... }+.
  #
  def send(sender, *args)
    self.mapper(self.method(:simple_call), sender, *args)
  end

  #
  # Send signal from sender to all connected receivers catching errors.
  # 
  # If any receiver raises an error (specifically any subclass of Exception),
  # the error instance is returned as the result for that receiver.
  # 
  # +sender+:: The sender of the signal. Either a specific object or nil.
  # +args+:: Args which will be passed to receivers.
  # 
  # Returns a hash +{receiver => response, ... }+.
  #
  def send_robust(sender, *args)
    self.mapper(self.method(:robust_call), sender, *args)
  end

  protected
  def make_key(receiver, sender, dispatch_uid=nil)
    [
      dispatch_uid || receiver.object_id,
      sender.object_id
    ]
  end

  def simple_call(receiver, sender, *args)
    opts = {}
    if args.last.is_a?(Hash)
      opts = args.pop
    end
    opts.merge!(
      :signal => self,
      :sender => sender
    )
    args.push(opts)

    receiver.call(*args)
  end

  def robust_call(receiver, sender, *args)
    begin
      simple_call(receiver, sender, *args)
    rescue WeakRef::RefError
      raise
    rescue Exception => e
      e
    end
  end

  def mapper(kaller, sender, *args)
    return {} if not @receivers

    this_sender_id = sender.object_id
    Hash[
      @receivers.select do |(receiver_id, target_sender_id), receiver|
        target_sender_id == nil.object_id or target_sender_id == this_sender_id
      end.map do |_, receiver|
        begin
          [
            receiver,
            kaller.call(receiver, sender, *args)
          ]
        rescue WeakRef::RefError
          @lock.synchronize {
            while (k = @receivers.key(receiver)) do
              @receivers.delete(k)
            end
          }
          next
        end
      end
    ]
  end
end
