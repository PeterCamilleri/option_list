# OptionList

This gem addresses the fact that parameter validation is long and
tedious and something needs to be done about that. This gem implements
the idea that parameters be described separately and validated in a
single line of client method code.

Most of what this gem does has been subsumed by the Ruby Language itself,
starting with version 1.9 and further with versions 2.0 and beyond.

Finally, I'd like to add a personal note about this code. This was my first
attempt at creating a gem. As such there is very much a newbie vibe to the
code. I hope you can chalk this up to just a part of the learning process.
None the less, if there are improvements that you (the reader) could suggest,
I'd really appreciate hearing about them.

Thanks in advance, Peter.


## Installation

Add this line to your application's Gemfile:

    gem 'option_list'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install option_list

## Usage

The use of option_list occurs in three phases: Describing the Parameters,
Passing in Parameters and Validating/Accessing the Parameters. This can be
seen in the following example:

    module ReadLine
      #Create the parameter specification (simplified for brevity)
      @spec = OptionList.new([:buffer, :history, :no_history], {:depth => 50}) do |options|
        fail "Depth must be an integer" unless options.depth.is_a(Integer)
        fail "Depth must be positive" if options.depth < 1
      end

      class << self
        attr_reader :spec
      end

      def read_line(prompt, *options)
        @options = ReadLine.spec.select(options)
        #Further code deleted for brevity.
        #Somewhere along the line it records the last line.
        buffer_line(current_line)
        current_line
      end

      def buffer_line(line)
        @line_buffer << line if @options.history?
        @line_buffer.delete_at(0) if @line_buffer.length > @options.depth
      end
    end

The option_list gem is described in the The option_list User's Guide
which covers version 1.1.1 which has no material change from 1.1.3

## Contributing

#### Plan A

1. Fork it ( https://github.com/PeterCamilleri/option_list/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

#### Plan B

Go to the GitHub repository and raise an issue calling attention to some
aspect that could use some TLC or a suggestion or an idea.
