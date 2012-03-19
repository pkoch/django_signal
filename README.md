# Django Signals

Because I really wanted something similar to Django Signals in Ruby.

The Observable module was almost, but not entirely, not over engineered.

 * It made me have an object as the observer, not just a generic callable.
 * It's not a self standing class. It has to be included by someone.
 * Solution is not obvious if an object has various observable concerns.
 * <code>add_observer</code> had everything to cause me reload problems.

## But, will this work as I expect?

First of all, I obviously didn't wire this signals to ActiveRecord.

Also, I took the liberty to make some adaptations. Namely:

 * No explicit weakref stuff. Want a weakref? Build if yourself.
   Invalid refs are handled gracefuly. Check the tests.
 * No providing_args, since they had no functional relevance.

## Installation

Just add it to your projects' `Gemfile`:

```ruby
gem "django_signal"
```

## Usage

https://docs.djangoproject.com/en/dev/topics/signals/#defining-and-sending-signals

## Credits

 * https://code.djangoproject.com/svn/django/trunk/django/dispatch/dispatcher.py
 * Gonçalo Silva (@goncalossilva) for teaching me how to cut gems.

---------------------------------------

Copyright © 2012 Paulo Köch, released under the MIT license
