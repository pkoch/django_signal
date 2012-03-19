# Django Signals

Because I really wanted something similar to Django Signals in Ruby.

The Observable module was almost, but not entirely, not over engineered.
  * It made me have an object as the observer, not just a generic callable.
  * It's not a self standing class. It has to be included by someone.
  * add_observer had everything to cause me reload problems.

## Credits

https://code.djangoproject.com/svn/django/trunk/django/dispatch/dispatcher.py

## Usage

https://docs.djangoproject.com/en/dev/topics/signals/#defining-and-sending-signals

## But, will this work as I expect?

First of all, I obviously didn't wire this signals to ActiveRecord.

Also, I took the liberty to make some adaptations. Namely:
 * No explicit weakref stuff. Want a weakref? Build if yourself.
   Invalid refs are handled gracefuly.
 * No providing_args, since they had no functional relevance.

## Installation

Just add it to your projects' `Gemfile`:

```ruby
gem "django_signal"
```

<hr/>

Copyright © 2012 Paulo Köch, released under the MIT license
