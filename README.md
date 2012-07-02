<img align="right" src="https://github.com/flgr/again/raw/gh-pages/images/again.png" alt="" width="100" height="100">

# again.rb: Your code reacting to every change #

## DESCRIPTION ##

again is the best way to iteratively develop with Ruby.

It monitors your application's code or any required library
for changes. In the likely event of a change, the code is
automatically loaded again.

## Why? ##

After seeing a [live stream](http://www.youtube.com/watch?v=zdLDYUNRErQ&feature=player_detailpage#t=532s)
of Markus Persson [hyper-incrementally developing a game for a 48h game development competition in Java](
http://news.ycombinator.com/item?id=2911696), where he debugged
his 3d rendering code by just changing expressions, hitting save
and instantly seeing the effect, I wanted to have support for
hyper-iterative development in Ruby. 

Change a color, save, switch to your application and it's changed.

again has been tested with Ruby 1.8, Ruby 1.9 and JRuby 1.6.2.
I use it for my personal development, including [Sinatra](
http://www.sinatrarb.com/) web development as well as
[Ruby/Gosu](http://www.libgosu.org/) game development.

(If anybody has a better link for the video of Markus Persson working incrementally,
[please drop me a mail](mailto:florian.s.gross@web.de)!)


## INSTALL ##

```sh
  gem install again
```

## SYNOPSIS ##

### Getting started with again ###

All you need to do to setup automatic reloading of your
code is to require again:

```ruby
  require 'again'       # ...and again and again
```

You should do this after all other libraries of your application
have already been loaded: Make it your last `require`.


### Controlling what to execute again ###

#### Not running start-up logic again ####

When again detects a change to a file, it will reexecute all code
in that file. This also applies to the main file of your application,
the one you actually run from the command line.

For method and class definitions, this is no problem and things will
work exactly as you expect.

You should however wrap the actual start-up logic of your application
like this:

```ruby
  # Current file being executed from command line?
  if __FILE__ == $PROGRAM_NAME then
    # Show them windows
    window = GameWindow.new
    window.show
  end
```

This is something that is good style anyway (in order to allow your
code to be used as a library): The above would only be executed on
direct execution from the command line; and not when the file is
loaded as a library. [More detailed explanation of `__FILE__ == $PROGRAM_NAME`](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/184607)

again actually invests some extra effort to make sure that
`__FILE__ == $PROGRAM_NAME` blocks will not be run again
after reloading your main application file.


#### Running additional code on reloads ####

You can also have logic that is only run on reloads:

```ruby
  if Again.reloaded? then
    puts "Hello again"
  end
```

This is useful when you want to reset your application into a
predictable state or when your frameworks need some special logic
to make sure that your changes will be picked up. (Such as clearing
routes in Sinatra, [see below](#sinatra-again).)


### gosu again ###

I'm using again for game development with Ruby, together with
[Ruby/Gosu](http://www.libgosu.org/). My code typically looks like this:

```ruby
  require 'rubygems'
  require 'gosu'
  # ...
  require 'again'
  
  include Gosu
  
  class GameWindow < Gosu::Window
    def initialize()
      @objects = ...
    end
    
    def update()
      @objects.each(&:update)
    rescue Exception => err
      handle_error(err)
    end

    def draw()
      @objects.each(&:draw)
    rescue Exception => err
      handle_error(err)
    end
    
    def handle_error(err)
      # Simple logic, but it does the trick
      STDERR.puts err, err.backtrace
      sleep 3
    end
  end
  
  # Current file being executed from command line?
  if __FILE__ == $PROGRAM_NAME then
    # Let's play
    window = GameWindow.new
    window.show
  end
```

Rescuing exceptions in `update()` and `draw()` and
handling them in a central place is a very good idea.
If you have uncaught exceptions in there, Gosu will
shutdown your application. This would kill our nice
incremental development loop in the case of an error.


### sinatra again ###

I also use again to incrementalize my [Sinatra](http://www.libgosu.org/) development.
This is very similar to the above Gosu example, but with
one special twist:

```ruby
  require 'rubygems'
  require 'sinatra'
  require 'json'
  # ...
  require 'again'
  
  if Again.reloaded? then
    # Here's the twist
    Sinatra::Application.routes.clear
  end
  
  get '/' do
    return "Awesome!"
  end
```

We need to clear the Application routes first. Otherwise
sinatra won't let us redefine our routes. That's all!


## LICENSE ##

(The MIT License)

Copyright (c) 2012, Florian Gross <florian.s.gross@web.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.